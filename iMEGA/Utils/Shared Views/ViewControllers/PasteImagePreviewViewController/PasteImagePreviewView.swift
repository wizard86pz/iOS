import FlexLayout
import MEGAL10n
import UIKit

class PasteImagePreviewView: UIView {
    private let containerView = UIView()
    lazy var contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.layer.shadowColor = MEGAAppColor.Black._000000.uiColor.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.15
        return view
    }()
    // MARK: - Internal properties
    var viewModel: PasteImagePreviewViewModel!
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIPasteboard.general.loadImage()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = MEGAAppColor.SharedView.pasteImageBorder.uiColor.cgColor
        return imageView
    }()
    
    lazy var buttonContainer = UIView()
    
    lazy var sendButton: UIButton  = {
        let button = UIButton()
        button.setTitle(Strings.Localizable.send, for: .normal)
        button.mnz_setupPrimary(traitCollection)
        return button
    }()
    
    lazy var cancelButton: UIButton  = {
        let button = UIButton()
        button.setTitle(Strings.Localizable.cancel, for: .normal)
        button.mnz_setupCancel(traitCollection)
        return button
    }()
    
    init(viewModel: PasteImagePreviewViewModel) {
        super.init(frame: .zero)
        
        self.viewModel = viewModel
     
        containerView.flex.alignItems(.center).justifyContent(.center).define { flex in
            flex.addItem(contentView).width(90%).maxHeight(85%).padding(20).backgroundColor(UIColor.systemBackground).define { flex in
                flex.addItem(imageView).marginBottom(23).maxHeight(350).shrink(1)
                
                flex.addItem(buttonContainer).width(100%).direction(UIDevice.current.orientation.isLandscape ? .row : .column).define { flex in
                    flex.addItem(sendButton).grow(1).height(50)
                    
                    flex.addItem(cancelButton).height(50).grow(1)
                }
      
            }
        }

        addSubview(containerView)

        sendButton.addTarget(self, action: #selector(PasteImagePreviewView.didTapSendButton), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(PasteImagePreviewView.didTapCancelButton), for: .touchUpInside)

    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewOrientationDidChange() {
        buttonContainer.flex.direction(UIDevice.current.orientation.isLandscape ? .row : .column)
        buttonContainer.flex.markDirty()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.pin.all()

        containerView.flex.layout()
    }
    
    @objc private func didTapSendButton() {
        viewModel.dispatch(.didClickSend)
    }
    
    @objc private func didTapCancelButton() {
        viewModel.dispatch(.didClickCancel)
    }
}
