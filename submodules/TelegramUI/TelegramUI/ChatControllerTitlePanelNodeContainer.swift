import Foundation
import UIKit
import AsyncDisplayKit
import AccountContext

// MARK: - iMe
final class ChatControllerTitlePanelNodeContainer: ASDisplayNode, ChatControllerTitlePanelNodeContainerInterface {
// MARK: -
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.bounds.contains(point) {
            var foundHit = false
            if let subnodes = self.subnodes {
                for subnode in subnodes {
                    if subnode.frame.contains(point) {
                        foundHit = true
                        break
                    }
                }
            }
            if !foundHit {
                return nil
            }
        }
        return super.hitTest(point, with: event)
    }
}
