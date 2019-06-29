//
//  UIViewController+Extension .swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/29/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import UIKit

extension UIViewController {

    func showAlert(withTitle: String = "Info", withMessage: String, action: (() -> Void)? = nil ) {
         DispatchQueue.main.async {
            let ac = UIAlertController(title: withTitle, message: withMessage, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in
                action?()
            }))
            self.present(ac, animated: true)
        }
    }
}
