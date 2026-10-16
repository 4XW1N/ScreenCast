//  VideoRenderView.swift
//  ScreenCast

import UIKit
import WebRTC

class VideoRenderView: UIView {
    private var renderer: RTCMTLVideoView?
    private var videoTrack: RTCVideoTrack?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRenderer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRenderer()
    }

    private func setupRenderer() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal not supported")
            return
        }

        renderer = RTCMTLVideoView(frame: bounds)
        renderer?.delegate = self
        renderer?.videoContentMode = .scaleAspectFit
        renderer?.backgroundColor = .black

        if let renderer = renderer {
            addSubview(renderer)
            renderer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                renderer.topAnchor.constraint(equalTo: topAnchor),
                renderer.bottomAnchor.constraint(equalTo: bottomAnchor),
                renderer.leadingAnchor.constraint(equalTo: leadingAnchor),
                renderer.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
    }

    func setVideoTrack(_ track: RTCVideoTrack?) {
        videoTrack = track
        videoTrack?.add(renderer!)
    }

    func removeVideoTrack() {
        videoTrack?.remove(renderer!)
        videoTrack = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        renderer?.frame = bounds
    }
}

extension VideoRenderView: RTCVideoViewDelegate {
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        print("Video size changed: \(size)")
    }
}