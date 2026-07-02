//
//  ContentCardInfoView.swift
//  App
//
//  Created by Venkatesh Mandapati on 08/06/2025.
//

import Foundation
import UIKit

protocol ContentCardInfoViewDelegate: AnyObject {
  func didTapOptions()
  func didTapMuteToggle()
  func didTapFlag()
  func didTapViewCount()
  func didTapTradingVolume()
  func didTapShare()
}

class ContentCardInfoView: UIView {

  weak var delegate: ContentCardInfoViewDelegate?

  private let isOwnProfile: Bool
  private let shouldShowFullScreen: Bool
  private let isMutedInitial: Bool
  private let showShareButton: Bool

  // MARK: UI Components
  
  func applyShadow(to view: UIView) {
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOpacity = 0.6
    view.layer.shadowOffset = CGSize(width: 0, height: 1)
    view.layer.shadowRadius = 2
    view.layer.masksToBounds = false
  }

  private lazy var optionsButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "exclamationmark.bubble")?.withRenderingMode(.alwaysTemplate), for: .normal)
    button.tintColor = .white
    button.addTarget(self, action: #selector(optionsTapped), for: .touchUpInside)
    button.isHidden = !isOwnProfile
    applyShadow(to: button)

    return button
  }()

  private lazy var muteButton: UIButton = {
    let button = UIButton(type: .system)
    updateMuteButtonIcon(isMuted: isMutedInitial, button: button)
    let imageName = isMutedInitial ? "speaker.slash" : "speaker.wave.2"
    button.setImage(UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
    button.tintColor = .white
    button.addTarget(self, action: #selector(muteTapped), for: .touchUpInside)
    applyShadow(to: button)
    return button
  }()

  private lazy var flagButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "exclamationmark.bubble")?.withRenderingMode(.alwaysTemplate), for: .normal)
    button.tintColor = .white
    button.addTarget(self, action: #selector(flagTapped), for: .touchUpInside)
    applyShadow(to: button)
    return button
  }()

  private lazy var viewCountButton: UIButton = {
    let button = UIButton(type: .system)
//    button.setImage(UIImage(named: "PlayRegular24")?.withRenderingMode(.alwaysTemplate), for: .normal)
    button.setImage(UIImage(systemName: "play")?.withRenderingMode(.alwaysTemplate), for: .normal)
    button.tintColor = .white
    button.addTarget(self, action: #selector(viewCountTapped), for: .touchUpInside)
    applyShadow(to: button)
    return button
  }()

  private lazy var viewCountLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    label.numberOfLines = 1
    label.text = "10"
    applyShadow(to: label)
    return label
  }()

  private lazy var tradingVolumeButton: UIButton = {
    let button = UIButton(type: .system)
//    button.setImage(UIImage(named: "DollarCircleRegular24")?.withRenderingMode(.alwaysTemplate), for: .normal)
    button.setImage(UIImage(systemName: "dollarsign.circle")?.withRenderingMode(.alwaysTemplate), for: .normal)
    button.tintColor = .white
    button.addTarget(self, action: #selector(tradingVolumeTapped), for: .touchUpInside)
    applyShadow(to: button)
    return button
  }()

  private lazy var tradingVolumeLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    label.numberOfLines = 1
    label.text = "$0"
    applyShadow(to: label)
    return label
  }()

  private lazy var shareButton: UIButton = {
    let button = UIButton(type: .system)
//    button.setImage(UIImage(named: "ShareContent24")?.withRenderingMode(.alwaysTemplate), for: .normal)
    button.setImage(UIImage(systemName: "arrowshape.turn.up.right")?.withRenderingMode(.alwaysTemplate), for: .normal)
    button.tintColor = .white
    button.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    button.isHidden = !showShareButton
    applyShadow(to: button)
    return button
  }()

  private lazy var shareLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    label.text = NSLocalizedString("Share", comment: "")
    label.isHidden = !showShareButton
    applyShadow(to: label)
    return label
  }()

  // MARK: Initialization

  init(
    isOwnProfile: Bool,
    isMuted: Bool,
    viewCount: Int?,
    tradingVolume: String?,
    shouldShowFullScreen: Bool,
    showShareButton: Bool
  ) {
    self.isOwnProfile = isOwnProfile
    self.shouldShowFullScreen = shouldShowFullScreen
    self.isMutedInitial = isMuted
    self.showShareButton = showShareButton

    super.init(frame: .zero)

    backgroundColor = .clear

    setupSubviews()
    setupConstraints()

    // Set labels if data available
    if let viewCount = viewCount {
      viewCountLabel.text = formatContentViews(Decimal(viewCount))
    }
    if let tradingVolume = tradingVolume {
      tradingVolumeLabel.text = "$" + formatContentDataValue(Decimal(string: tradingVolume) ?? 0)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Setup UI

  private func setupSubviews() {
    addSubview(optionsButton)
    addSubview(muteButton)
    addSubview(flagButton)

    addSubview(viewCountButton)
    addSubview(viewCountLabel)

    addSubview(tradingVolumeButton)
    addSubview(tradingVolumeLabel)

    addSubview(shareButton)
    addSubview(shareLabel)
  }

  private func setupConstraints() {
    // We'll position vertically on the right side with spacing,
    // similar to your RN layout: top group (options, mute, flag), bottom group (view count, trading, share)
    // And add safe area padding top if shouldShowFullScreen is true.

    optionsButton.translatesAutoresizingMaskIntoConstraints = false
    muteButton.translatesAutoresizingMaskIntoConstraints = false
    flagButton.translatesAutoresizingMaskIntoConstraints = false
    viewCountButton.translatesAutoresizingMaskIntoConstraints = false
    viewCountLabel.translatesAutoresizingMaskIntoConstraints = false
    tradingVolumeButton.translatesAutoresizingMaskIntoConstraints = false
    tradingVolumeLabel.translatesAutoresizingMaskIntoConstraints = false
    shareButton.translatesAutoresizingMaskIntoConstraints = false
    shareLabel.translatesAutoresizingMaskIntoConstraints = false

    let safeTopInset = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
    let topPadding = shouldShowFullScreen ? safeTopInset + 8 : 16

    NSLayoutConstraint.activate([

      // TOP SECTION

      optionsButton.topAnchor.constraint(equalTo: topAnchor, constant: topPadding),
      optionsButton.centerXAnchor.constraint(equalTo: centerXAnchor),

      muteButton.topAnchor.constraint(equalTo: optionsButton.bottomAnchor, constant: 8),
      muteButton.centerXAnchor.constraint(equalTo: centerXAnchor),

      flagButton.topAnchor.constraint(equalTo: muteButton.bottomAnchor, constant: 8),
      flagButton.centerXAnchor.constraint(equalTo: centerXAnchor),

      // View count (play) at bottom
      // Share button at bottom
      shareButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -204),
      shareButton.centerXAnchor.constraint(equalTo: centerXAnchor),

      shareLabel.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 2),
      shareLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      shareLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 40),

      // Trading volume ABOVE share
      tradingVolumeButton.bottomAnchor.constraint(equalTo: shareButton.topAnchor, constant: -46),
      tradingVolumeButton.centerXAnchor.constraint(equalTo: centerXAnchor),

      tradingVolumeLabel.topAnchor.constraint(equalTo: tradingVolumeButton.bottomAnchor, constant: 2),
      tradingVolumeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      tradingVolumeLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 50),

      // View count ABOVE trading volume
      viewCountButton.bottomAnchor.constraint(equalTo: tradingVolumeButton.topAnchor, constant: -46),
      viewCountButton.centerXAnchor.constraint(equalTo: centerXAnchor),

      viewCountLabel.topAnchor.constraint(equalTo: viewCountButton.bottomAnchor, constant: 2),
      viewCountLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      viewCountLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 40),

    ])

  }

  // MARK: Helpers

  private func updateMuteButtonIcon(isMuted: Bool, button: UIButton) {
    let imageName = isMuted ? "speaker.slash" : "speaker.wave.2"
    button.setImage(UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
  }

  func updateMuteState(isMuted: Bool) {
    updateMuteButtonIcon(isMuted: isMuted, button: muteButton)
  }

  func updateViewCount(_ count: Int) {
    viewCountLabel.text = formatContentViews(Decimal(count))
  }

  func updateTradingVolume(_ volume: String) {
    tradingVolumeLabel.text = "$" + formatContentDataValue(Decimal(string: volume) ?? 0)
  }

  // MARK: Button Actions

  @objc private func optionsTapped() {
    delegate?.didTapOptions()
  }

  @objc private func muteTapped() {
    delegate?.didTapMuteToggle()
  }

  @objc private func flagTapped() {
    delegate?.didTapFlag()
  }

  @objc private func viewCountTapped() {
    delegate?.didTapViewCount()
  }

  @objc private func tradingVolumeTapped() {
    delegate?.didTapTradingVolume()
  }

  @objc private func shareTapped() {
    delegate?.didTapShare()
  }
}

// Helpers to mimic your formatting from RN utils:

import Foundation

func formatContentViews(_ value: Decimal) -> String {
  // Simplified format, e.g. 1.2K, 3.5M
  if value >= 1_000_000 {
    return String(format: "%.1fM", NSDecimalNumber(decimal: value).doubleValue / 1_000_000)
  }
  if value >= 1_000 {
    return String(format: "%.1fK", NSDecimalNumber(decimal: value).doubleValue / 1_000)
  }
  return NSDecimalNumber(decimal: value).stringValue
}

func formatContentDataValue(_ value: Decimal) -> String {
  // Format trading volume, e.g. 12.3K, 1.5M
  return formatContentViews(value)
}
