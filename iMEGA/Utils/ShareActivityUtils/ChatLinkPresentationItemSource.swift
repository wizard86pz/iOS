import LinkPresentation

class ChatLinkPresentationItemSource: NSObject, UIActivityItemSource {
    private let title: String
    private let subject: String
    private let message: String
    private let url: URL
    
    init(title: String, subject: String, message: String, url: URL) {
        self.title = title
        self.subject = subject
        self.message = message
        self.url = url
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let linkMetaData = LPLinkMetadata()
        linkMetaData.iconProvider = NSItemProvider(object: UIImage(resource: .megaShareContactLink))
        linkMetaData.title = title
        return linkMetaData
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        message
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        subject
    }
}
