import AVFoundation

enum SlotSounds {
    private static var spinLoopPlayer: AVAudioPlayer?
    private static var tickTask: Task<Void, Never>?
    private static var players: [String: AVAudioPlayer] = [:]
    private static var tickPlayers: [AVAudioPlayer] = []
    private static var isPrepared = false

    static func prepare() {
        guard !isPrepared else { return }
        isPrepared = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        for name in ["spin_pull", "spin_loop", "winner"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else { continue }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[name] = player
            }
        }

        tickPlayers = (1 ... 6).compactMap { index in
            guard let url = Bundle.main.url(forResource: "reel_tick_\(index)", withExtension: "caf") else { return nil }
            guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
            player.prepareToPlay()
            player.enableRate = true
            return player
        }

        spinLoopPlayer = players["spin_loop"]
        spinLoopPlayer?.numberOfLoops = -1
        spinLoopPlayer?.volume = 0.38
        spinLoopPlayer?.enableRate = true
    }

    static func beginSpin(duration: TimeInterval) {
        prepare()
        stopSpinLoop()
        tickTask?.cancel()

        playOneShot("spin_pull", volume: 0.95)
        startSpinLoop(rate: 1.0)

        tickTask = Task { @MainActor in
            var elapsed: TimeInterval = 0
            let end = max(0.2, duration - 0.12)
            let minInterval = 0.042
            let maxInterval = 0.165

            while elapsed < end {
                if Task.isCancelled { return }

                let progress = min(1, elapsed / duration)
                let interval = minInterval + progress * (maxInterval - minInterval)
                let loopRate = Float(1.0 - progress * 0.38)
                spinLoopPlayer?.rate = max(0.58, loopRate)

                try? await Task.sleep(for: .seconds(interval))
                if Task.isCancelled { return }

                playReelTick(volume: 0.5 + Float(progress) * 0.3)
                elapsed += interval
            }
        }
    }

    static func finishWithWinner() {
        tickTask?.cancel()
        tickTask = nil
        stopSpinLoop()
        playOneShot("winner", volume: 1.0)
    }

    static func cancel() {
        tickTask?.cancel()
        tickTask = nil
        stopSpinLoop()
    }

    private static func startSpinLoop(rate: Float) {
        guard let spinLoopPlayer else { return }
        spinLoopPlayer.currentTime = 0
        spinLoopPlayer.rate = rate
        spinLoopPlayer.play()
    }

    private static func stopSpinLoop() {
        spinLoopPlayer?.stop()
        spinLoopPlayer?.currentTime = 0
        spinLoopPlayer?.rate = 1.0
    }

    private static func playReelTick(volume: Float) {
        guard !tickPlayers.isEmpty else { return }
        let index = Int.random(in: 0 ..< tickPlayers.count)
        let player = tickPlayers[index]
        player.stop()
        player.currentTime = 0
        player.volume = volume
        player.rate = Float.random(in: 0.98 ... 1.02)
        player.play()
    }

    private static func playOneShot(_ name: String, volume: Float) {
        guard let player = players[name] else { return }
        player.stop()
        player.currentTime = 0
        player.volume = volume
        player.play()
    }
}
