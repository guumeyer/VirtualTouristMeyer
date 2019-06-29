//
//  PhotoAlbumCell.swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/29/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import UIKit

final class PhotoAlbumCell: UICollectionViewCell {

    @IBOutlet weak var activeIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    static let identifier = "PhotoAlbumCell"

    override var isSelected: Bool {
        didSet {
            alpha = isSelected ? 0.7 : 1
        }
    }

    override func prepareForReuse() {
        alpha = 1
        backgroundColor = .lightGray
        imageView.image = nil
        activeIndicator.isHidden = false
        activeIndicator.startAnimating()
    }

    func noImageAvailable() {
        activeIndicator.stopAnimating()
        activeIndicator.isHidden = true
        backgroundColor = .white
        imageView.image = UIImage(named: "noImageAvailable")
    }

    func configure(data: Data?) {
        imageView.image = nil
        activeIndicator.isHidden = false
        activeIndicator.startAnimating()

        if let imageData = data {
            activeIndicator.stopAnimating()
            activeIndicator.isHidden = true
            imageView.image = UIImage(data: imageData)
        }
    }

}
