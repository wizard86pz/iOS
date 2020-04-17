
import UIKit

class RichPreviewContentView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    var message : MEGAChatMessage? {
        didSet {
            if message?.richNumber == nil {
                return
            }
            configureView()
        }
    }

    func configureView() {
        let megaLink = message!.megaLink as NSURL
        switch megaLink.mnz_type() {
        case .fileLink:
            let node = message?.node
            titleLabel.text = node?.name
            descriptionLabel.text = Helper.memoryStyleString(fromByteCount: Int64(truncating: node?.size ?? 0))
            linkLabel.text = "mega.nz"
            iconImageView.image = UIImage(named: "favicon")
            imageView.mnz_setThumbnail(by: node)
            
        case .folderLink:
            titleLabel.text = message?.richTitle
            descriptionLabel.text = String(format: "%@\n%@", message!.richString, Helper.memoryStyleString(fromByteCount: max(message!.richNumber.int64Value, 0)))
            linkLabel.text = "mega.nz"
            iconImageView.image = UIImage(named: "favicon")
            imageView.image = UIImage.mnz_folder()
            
        case .publicChatLink:
            titleLabel.text = message?.richString
            descriptionLabel.text = String(format: "%lld %@", message!.richNumber.int64Value, AMLocalizedString("participants", "Label to describe the section where you can see the participants of a group chat"))
            linkLabel.text = "mega.nz"
            iconImageView.image = UIImage(named: "favicon")
            imageView.image = UIImage(named: "groupChat")

        default:
            break
        }
    }
}
