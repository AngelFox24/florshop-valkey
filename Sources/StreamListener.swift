import Vapor
import VaporValkey
import Valkey
import FlorShopDTOs

public struct StreamListener {
    let streamName: String
    let groupName: String
    let consumerName: String
    
    public init(
        streamName: ValkeyStream,
        groupName: String,
        consumerName: String
    ) {
        self.streamName = streamName.rawValue
        self.groupName = groupName
        self.consumerName = consumerName
    }
    
    /// Comienza a escuchar mensajes en el stream.
    /// El closure `handler` recibe los campos del mensaje y debe devolver `true` si se debe hacer ACK.
    public func start(on app: Application, handler: @escaping @Sendable ([String: String]) async -> Bool) async {
        // 1. Crear grupo
        do {
            try await app.valkey.xgroupCreate(
                ValkeyKey(self.streamName),
                group: self.groupName,
                idSelector: .id("0"),
                mkstream: true
            )
            app.logger.notice("Grupo '\(self.groupName)' listo")
        } catch let error where error.errorCode == .commandError {
            app.logger.info("Grupo '\(self.groupName)' ya existía, continuamos")
        } catch {
            app.logger.error("Error inesperado al crear grupo: \(error)")
            return
        }
        
        // 2. Bucle de lectura
        while !Task.isCancelled {
            do {
                try await readAndProcess(app: app, handler: handler)
            } catch {
                app.logger.error("Error en el stream '\(self.streamName)': \(error)")
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }
    
    private func readAndProcess(
        app: Application,
        handler: @escaping @Sendable ([String: String]) async -> Bool
    ) async throws {
        while !Task.isCancelled {
            let response = try await app.valkey.xreadgroup(
                groupBlock: .init(group: groupName, consumer: consumerName),
                milliseconds: 5000,
                streams: .init(
                    keys: [ValkeyKey(streamName)],
                    ids: [">" as String]
                )
            )
            
            guard let streams = response else { continue }
            
            for stream in streams.streams {
                for message in stream.messages {
                    let fields = message.fieldDictionary
                    let messageId = String(message.id)
                    
                    // Llamamos al handler, él decide si confirma
                    let shouldAck = await handler(fields)
                    
                    if shouldAck {
                        _ = try await app.valkey.xack(
                            ValkeyKey(streamName),
                            group: groupName,
                            ids: [messageId]
                        )
                        app.logger.info("✅ ACK enviado para \(messageId)")
                    } else {
                        app.logger.warning("⚠️ No se confirmó el mensaje \(messageId), se reintentará más tarde")
                    }
                }
            }
        }
    }
}

extension XREADGroupMessage {
    var fieldDictionary: [String: String] {
        guard let fields = self.fields else { return [:] }
        var dict: [String: String] = [:]
        for (key, value) in fields {
            dict[key] = String(value)
        }
        return dict
    }
}
