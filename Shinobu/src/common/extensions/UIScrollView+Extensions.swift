import UIKit

extension UIScrollView {
    func scrollToTop(animated: Bool) {
        let topContentOffset = CGPoint(-safeAreaInsets.left, -safeAreaInsets.top)
        setContentOffset(topContentOffset, animated: animated)
    }
}
