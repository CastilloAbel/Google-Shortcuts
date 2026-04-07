import Foundation
import AVFoundation
import MediaPlayer

/// Servicio para acceder a información de audio y media
@MainActor
final class AudioMediaService {
    static let shared = AudioMediaService()
    
    private init() {}
    
    /// Obtiene el estado actual de audio y media
    func getStatus() -> AudioMediaStatus {
        return AudioMediaStatus(
            isAudioPlaying: isAudioPlaying(),
            playbackDestination: getPlaybackDestination(),
            isSilentModeOn: isSilentModeOn(),
            systemVolume: getSystemVolume()
        )
    }
    
    /// Verifica si hay audio reproduciéndose
    private func isAudioPlaying() -> Bool {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            return audioSession.isOtherAudioPlaying
        } catch {
            return false
        }
    }
    
    /// Obtiene el destino actual de reproducción de audio
    private func getPlaybackDestination() -> AudioMediaStatus.AudioDestination {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            let category = audioSession.category
            var outputs: [AVAudioSession.Port] = []
            
            do {
                outputs = try AVAudioSession.sharedInstance().currentRoute.outputs.map(\.portType)
            } catch {
                return .unknown
            }
            
            // Verificar qué dispositivos están conectados
            for output in outputs {
                if output == .headphones || output == .headsetMic {
                    return .headphones
                }
                if output == .bluetoothA2DP || output == .bluetoothHFP {
                    return .bluetoothA2DP
                }
                if output == .airPlay {
                    return .airplay
                }
                if output == .hdmi {
                    return .hdmi
                }
                if output == .builtInSpeaker {
                    return .builtInSpeaker
                }
            }
            
            return .speaker
        } catch {
            return .unknown
        }
    }
    
    /// Verifica si el dispositivo está en modo silencioso
    private func isSilentModeOn() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        // En iOS, el modo silencioso es cuando el switch física está en Silent
        // No hay API directa, pero podemos inferirlo del volumen
        return audioSession.outputVolume == 0
    }
    
    /// Obtiene el volumen del sistema (0.0-1.0)
    private func getSystemVolume() -> Float {
        return AVAudioSession.sharedInstance().outputVolume
    }
}
