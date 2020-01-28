import UIKit

extension UISearchBar {
    func setSearchBarColor(color: UIColor) {
        UIGraphicsBeginImageContext(frame.size)
        color.setFill()
        UIBezierPath(rect: frame).fill()
        let bgImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        setSearchFieldBackgroundImage(bgImage, for: .normal)
    }
}
