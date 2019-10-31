import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
// MARK: - iMe
import iMeUI


enum PlaceholderType {
    case standard, folders, unread, channels

    func title(_ strings: PresentationStrings) -> String {
        switch self {
            case .standard: return strings.DialogList_NoMessagesTitle
            case .folders: return strings.DialogList_NoFoldersTitle
            case .unread: return strings.DialogList_NoUnreadTitle
            case .channels: return strings.DialogList_NoChannelsTitle
        }
    }

    func text(_ strings: PresentationStrings) -> String {
        switch self {
            case .standard: return strings.DialogList_NoMessagesText
            case .folders: return strings.DialogList_NoFoldersText
            case .unread: return strings.DialogList_NoUnreadText
            case .channels: return strings.DialogList_NoChannelsText
        }
    }
}
// MARK: -

final class ChatListEmptyNode: ASDisplayNode {
    private let textNode: ImmediateTextNode
    
    private var validLayout: CGSize?
    
    // MARK: - iMe
    var placeholderType: PlaceholderType
    // MARK: -
    
    // MARK: - iMe
    init(theme: PresentationTheme, strings: PresentationStrings, placeholderType: PlaceholderType = .standard) {
        self.placeholderType = placeholderType
    // MARK: -
        
        self.textNode = ImmediateTextNode()
        self.textNode.displaysAsynchronously = false
        self.textNode.maximumNumberOfLines = 0
        self.textNode.isUserInteractionEnabled = false
        self.textNode.textAlignment = .center
        self.textNode.lineSpacing = 0.1
        
        super.init()
        
        self.addSubnode(self.textNode)
        
        self.updateThemeAndStrings(theme: theme, strings: strings)
    }
    
    func updateThemeAndStrings(theme: PresentationTheme, strings: PresentationStrings) {
        let string = NSMutableAttributedString()
        // MARK: - iMe
        string.append(NSAttributedString(string: placeholderType.title(strings) + "\n", font: Font.medium(17.0), textColor: theme.list.itemSecondaryTextColor, paragraphAlignment: .center))
        // MARK: -
        string.append(NSAttributedString(string: strings.DialogList_NoMessagesText, font: Font.regular(16.0), textColor: theme.list.itemSecondaryTextColor, paragraphAlignment: .center))
        self.textNode.attributedText = string
        
        if let size = self.validLayout {
            self.updateLayout(size: size, transition: .immediate)
        }
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        self.validLayout = size
        
        let textSize = self.textNode.updateLayout(CGSize(width: size.width - 40.0, height: size.height))
        transition.updateFrame(node: self.textNode, frame: CGRect(origin: CGPoint(x: floor((size.width - textSize.width) / 2.0), y: floor((size.height - textSize.height) / 2.0)), size: textSize))
    }
}

// MARK: - iMe
extension ChatListEmptyNode: ChatListEmptyNodeInterface {}
// MARK: -
