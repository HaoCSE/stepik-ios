//
//  StepikPlaceholderView.swift
//  Stepic
//
//  Created by Vladislav Kiryukhin on 16.03.2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

protocol StepikPlaceholderViewDelegate: class {
    func buttonDidClick(_ button: UIButton)
}

class StepikPlaceholderView: NibInitializableView {
    struct maxHeight {
        static let horizontal = CGFloat(500)
        static let vertical = CGFloat(500)
    }

    struct imageHeightToFrameHeightRatio {
        static let horizontal = CGFloat(0.75)
        static let vertical = CGFloat(0.5)
    }

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var actionsStackView: UIStackView!

    lazy private var allPlaceholders: [StepikPlaceholderStyle.PlaceholderId: StepikPlaceholderStyle] = {
        var idToView: [StepikPlaceholderStyle.PlaceholderId: StepikPlaceholderStyle] = [:]
        for placeholder in StepikPlaceholder.availablePlaceholders {
            idToView[placeholder.id] = placeholder
        }
        return idToView
    }()

    private var currentPlaceholder: StepikPlaceholderStyle?

    weak var delegate: StepikPlaceholderViewDelegate?

    override var nibName: String {
        return "StepikPlaceholderView"
    }

    @IBAction func onActionButtonClick(_ sender: Any) {
        delegate?.buttonDidClick(actionButton)
    }

    override func setupSubviews() {
        actionButton.clipsToBounds = true
        actionButton.layer.cornerRadius = 8
        actionButton.layer.borderWidth = 0.5
        actionButton.layer.borderColor = UIColor(red: 204 / 255, green: 204 / 255, blue: 204 / 255, alpha: 1.0).cgColor

        actionButton.contentEdgeInsets = UIEdgeInsets(top: 14.0, left: 25.0, bottom: 14.0, right: 25.0)
        actionButton.setTitleColor(UIColor(red: 83 / 255, green: 83 / 255, blue: 102 / 255, alpha: 1.0), for: .normal)
    }

    private func rebuildConstraints(for placeholder: StepikPlaceholderStyle) {
        let isVertical = bounds.width < bounds.height

        let hasImage = placeholder.image != nil
        let imageRatio = (placeholder.image?.image.size.width ?? 1) / (placeholder.image?.image.size.height ?? 1)
        stackView.layoutIfNeeded()

        var framedImageHeight = CGFloat(0.0)
        var scaleFactor = CGFloat(1.0)
        if hasImage {
            if isVertical {
                framedImageHeight = min(maxHeight.vertical, bounds.height * imageHeightToFrameHeightRatio.vertical)
            } else {
                framedImageHeight = min(maxHeight.horizontal, bounds.height * imageHeightToFrameHeightRatio.horizontal)
            }
            let elementSizes = allPlaceholders.values.flatMap({ $0.image }).map({ $0.scale * framedImageHeight })
            let currentElementSize = placeholder.image!.scale * framedImageHeight
            let minElementSize = elementSizes.min() ?? 0.0
            scaleFactor = currentElementSize > 0 ? minElementSize / currentElementSize : 1
        }

        imageViewHeightConstraint.constant = scaleFactor * framedImageHeight
        imageViewWidthConstraint.constant = imageViewHeightConstraint.constant * imageRatio

        if isVertical {
            stackView.axis = .vertical
            stackView.distribution = .equalCentering
        } else {
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async { [weak self] in
            if let currentPlaceholder = self?.currentPlaceholder {
                self?.rebuildConstraints(for: currentPlaceholder)
            }
        }
    }

    func set(id: StepikPlaceholderStyle.PlaceholderId) {
        guard let placeholderWithId = allPlaceholders[id] else {
            return
        }

        currentPlaceholder = placeholderWithId

        imageView.image = placeholderWithId.image?.image
        textLabel.text = placeholderWithId.text
        actionButton.setTitle(placeholderWithId.buttonTitle, for: .normal)

        rebuildConstraints(for: placeholderWithId)
    }
}
