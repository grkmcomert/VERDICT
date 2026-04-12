import Flutter
import UIKit
import google_mobile_ads

final class NativeAdFactoryExample: NSObject, FLTNativeAdFactory {

    func createNativeAd(
        _ nativeAd: GADNativeAd,
        customOptions: [AnyHashable : Any]? = nil
    ) -> GADNativeAdView? {
        let nativeAdView = GADNativeAdView(frame: .zero)
        nativeAdView.backgroundColor = .clear

        let cardView = UIView(frame: .zero)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        cardView.layer.cornerRadius = 14
        cardView.clipsToBounds = true
        nativeAdView.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor)
        ])

        let containerStack = UIStackView(frame: .zero)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        containerStack.axis = .vertical
        containerStack.spacing = 8
        cardView.addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 10),
            containerStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -10),
            containerStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            containerStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10)
        ])

        let iconView = UIImageView(frame: .zero)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 10
        iconView.clipsToBounds = true
        iconView.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        let iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: 40)
        let iconHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: 40)
        NSLayoutConstraint.activate([iconWidthConstraint, iconHeightConstraint])

        let headlineLabel = makeLabel(
            font: .systemFont(ofSize: 16, weight: .bold),
            color: .black,
            numberOfLines: 1
        )
        let advertiserLabel = makeLabel(
            font: .systemFont(ofSize: 11, weight: .medium),
            color: .darkGray,
            numberOfLines: 1
        )

        let titleStack = UIStackView(arrangedSubviews: [headlineLabel, advertiserLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        let headerRow = UIStackView(arrangedSubviews: [iconView, titleStack])
        headerRow.axis = .horizontal
        headerRow.spacing = 10
        headerRow.alignment = .center

        let mediaView = GADMediaView(frame: .zero)
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 12
        mediaView.backgroundColor = UIColor(white: 0.93, alpha: 1.0)
        let mediaHeightConstraint = mediaView.heightAnchor.constraint(equalToConstant: 128)
        mediaHeightConstraint.isActive = true

        let bodyLabel = makeLabel(
            font: .systemFont(ofSize: 13, weight: .regular),
            color: .black,
            numberOfLines: 2
        )

        let callToActionButton = UIButton(type: .system)
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.backgroundColor = UIColor(red: 0.13, green: 0.42, blue: 0.88, alpha: 1.0)
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        callToActionButton.layer.cornerRadius = 10
        callToActionButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        callToActionButton.setContentHuggingPriority(.required, for: .horizontal)
        callToActionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        callToActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96).isActive = true

        let priceLabel = makeLabel(
            font: .systemFont(ofSize: 11, weight: .medium),
            color: .darkGray,
            numberOfLines: 1
        )
        let storeLabel = makeLabel(
            font: .systemFont(ofSize: 11, weight: .medium),
            color: .darkGray,
            numberOfLines: 1
        )
        let ratingLabel = makeLabel(
            font: .systemFont(ofSize: 11, weight: .semibold),
            color: UIColor(red: 0.94, green: 0.63, blue: 0.09, alpha: 1.0),
            numberOfLines: 1
        )

        let detailsStack = UIStackView(arrangedSubviews: [priceLabel, storeLabel, ratingLabel])
        detailsStack.axis = .vertical
        detailsStack.spacing = 2
        detailsStack.alignment = .leading

        let footerRow = UIStackView(arrangedSubviews: [callToActionButton, detailsStack])
        footerRow.axis = .horizontal
        footerRow.spacing = 10
        footerRow.alignment = .center

        containerStack.addArrangedSubview(headerRow)
        containerStack.addArrangedSubview(mediaView)
        containerStack.addArrangedSubview(bodyLabel)
        containerStack.addArrangedSubview(footerRow)

        nativeAdView.iconView = iconView
        nativeAdView.headlineView = headlineLabel
        nativeAdView.advertiserView = advertiserLabel
        nativeAdView.mediaView = mediaView
        nativeAdView.bodyView = bodyLabel
        nativeAdView.callToActionView = callToActionButton
        nativeAdView.priceView = priceLabel
        nativeAdView.storeView = storeLabel
        nativeAdView.starRatingView = ratingLabel

        headlineLabel.text = nativeAd.headline
        mediaView.mediaContent = nativeAd.mediaContent

        if let iconImage = nativeAd.icon?.image {
            iconView.image = iconImage
            iconView.isHidden = false
            iconWidthConstraint.constant = 40
            iconHeightConstraint.constant = 40
        } else {
            iconView.isHidden = true
            iconWidthConstraint.constant = 0
            iconHeightConstraint.constant = 0
        }

        if nativeAd.mediaContent.aspectRatio > 0 {
            mediaHeightConstraint.constant = 128
        }

        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil

        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        callToActionButton.isHidden = nativeAd.callToAction == nil

        priceLabel.text = nativeAd.price
        priceLabel.isHidden = nativeAd.price == nil

        storeLabel.text = nativeAd.store
        storeLabel.isHidden = nativeAd.store == nil

        advertiserLabel.text = nativeAd.advertiser
        advertiserLabel.isHidden = nativeAd.advertiser == nil

        if let starValue = nativeAd.starRating?.doubleValue {
            ratingLabel.text = String(format: "Rating %.1f", starValue)
            ratingLabel.isHidden = false
        } else {
            ratingLabel.isHidden = true
        }

        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        nativeAdView.nativeAd = nativeAd

        return nativeAdView
    }

    private func makeLabel(
        font: UIFont,
        color: UIColor,
        numberOfLines: Int
    ) -> UILabel {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = font
        label.textColor = color
        label.numberOfLines = numberOfLines
        label.lineBreakMode = .byTruncatingTail
        return label
    }
}
