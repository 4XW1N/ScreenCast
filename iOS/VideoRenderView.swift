//  VideoRenderView.swift
//  ScreenCast

import UIKit

class VideoRenderView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
    }
}