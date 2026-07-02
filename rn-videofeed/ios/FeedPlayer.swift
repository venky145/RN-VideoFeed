//
//  FeedPlayer.swift
//  App
//
//  Created by Venkatesh Mandapati on 15/05/2025.
//



import Foundation
import AVFoundation

class FeedPlayer: UIView {
    private(set) var player: AVPlayer?
    private(set) var playerLayer: AVPlayerLayer?
    var onVideoStartedPlaying: (() -> Void)?
    private var timeControlStatusObserver: NSKeyValueObservation?
  
    @objc var videoUrl: NSString? {
        didSet {
            print("FeedPlayer - Setting video URL:", videoUrl ?? "nil")
            if let videoUrl = videoUrl as String? {
                setupPlayer(with: videoUrl)
            }
        }
    }

    @objc var id: NSString = "" {
        didSet {
            print("FeedPlayer - Setting ID:", id)
        }
    }

    @objc var isVisible: Bool = true {
        didSet {
            print("FeedPlayer - Setting visibility:", isVisible)
            if isVisible {
                player?.play()
            } else {
                player?.pause()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPlayer(with urlString: String) {
        print("FeedPlayer - Setting up player with URL:", urlString)
        guard let url = URL(string: urlString) else {
            print("⚠️ Invalid URL: \(urlString)")
            return
        }
      
      // Ensure audio plays even on silent
          do {
              try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
              try AVAudioSession.sharedInstance().setActive(true)
          } catch {
              print("Failed to set AVAudioSession:", error)
          }

        // Clean up
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        if let oldItem = player?.currentItem {
            oldItem.removeObserver(self, forKeyPath: "presentationSize")
        }

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        playerItem.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)

        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = false

        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
      playerLayer?.videoGravity = .resizeAspect

        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }

        // Observe timeControlStatus to detect when video actually starts playing
        timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            if player.timeControlStatus == .playing {
                DispatchQueue.main.async {
                    self?.onVideoStartedPlaying?()
                }
            }
        }

        // Loop
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }

        if isVisible {
            player?.play()
        }
    }

    func reset() {
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        onVideoStartedPlaying = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    deinit {
        reset()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - KVO Observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    print("✅ FeedPlayer - Ready to play")
                case .failed:
                    if let error = item.error {
                        print("❌ FeedPlayer - Player item failed: \(error.localizedDescription)")
                        
                        // Check for specific HTTP errors (404, etc.)
                        if let nsError = error as NSError? {
                            if nsError.domain == NSURLErrorDomain {
                                switch nsError.code {
                                case NSURLErrorFileDoesNotExist, NSURLErrorCannotFindHost:
                                    print("🚨 FeedPlayer - 404 Error: Video file not found")
                                case NSURLErrorNotConnectedToInternet:
                                    print("🚨 FeedPlayer - Network Error: No internet connection")
                                case NSURLErrorTimedOut:
                                    print("🚨 FeedPlayer - Timeout Error: Request timed out")
                                case NSURLErrorCannotConnectToHost:
                                    print("🚨 FeedPlayer - Connection Error: Cannot connect to host")
                                default:
                                    print("🚨 FeedPlayer - Network Error: \(nsError.localizedDescription)")
                                }
                            }
                        }
                    }
                case .unknown:
                    print("⚠️ FeedPlayer - Unknown status")
                @unknown default:
                    break
                }
            }
        }
    }
}
