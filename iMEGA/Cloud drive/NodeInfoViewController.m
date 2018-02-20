
#import "NodeInfoViewController.h"
#import "Helper.h"
#import "UIImage+MNZCategory.h"
#import "MEGASdkManager.h"
#import "NodePropertyTableViewCell.h"
#import "NodeTappablePropertyTableViewCell.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAExportRequestDelegate.h"
#import "MEGANavigationController.h"

#import "SVProgressHUD.h"
#import "ContactsViewController.h"
#import "GetLinkTableViewController.h"
#import "CloudDriveTableViewController.h"
#import "CustomActionViewController.h"
#import "BrowserViewController.h"

@interface MegaNodeProperty : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *value;

@end

@implementation MegaNodeProperty

- (instancetype)initWithTitle:(NSString *)title value:(NSString*)value {
    self = [super init];
    if (self) {
        _title = title;
        _value = value;
    }
    return self;
}

@end

@interface NodeInfoViewController () <UITableViewDelegate, UITableViewDataSource, CustomActionViewControllerDelegate, MEGADelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (strong, nonatomic) NSArray<MegaNodeProperty *> *nodeProperties;
@property (nonatomic) MEGAExportRequestDelegate *exportDelegate;

@end

@implementation NodeInfoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureView];
    
    self.exportDelegate = [[MEGAExportRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        [SVProgressHUD dismiss];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.node.isFolder ? 1 : 0) inSection:1];
        NodeTappablePropertyTableViewCell *linkCell = [self.tableView cellForRowAtIndexPath:indexPath];
        linkCell.titleLabel.text = [request link];
    } multipleLinks:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
}

#pragma mark - Layout

- (void)configureView {
    self.cancelBarButtonItem.title = AMLocalizedString(@"close", nil);
    [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem];
    
    [self reloadUI];
}

- (void)reloadUI {
    self.nodeProperties = [self nodePropertyCells];

    self.title = AMLocalizedString(@"info", nil);
    self.nameLabel.text = self.node.name;
    if (self.node.type == MEGANodeTypeFile) {
        if (self.node.hasThumbnail) {
            [Helper thumbnailForNode:self.node api:[MEGASdkManager sharedMEGASdk] cell:self.thumbnailImageView];
        } else {
            [self.thumbnailImageView setImage:[Helper imageForNode:self.node]];
        }
    } else if (self.node.type == MEGANodeTypeFolder) {
        [self.thumbnailImageView setImage:[Helper imageForNode:self.node]];
    }
    
    [self.tableView reloadData];
}

#pragma mark - TableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 44;
    } else {
        return 60;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewCell *sectionHeader = [self.tableView dequeueReusableCellWithIdentifier:@"nodeInfoHeader"];
    
    UILabel *titleSection = (UILabel*)[sectionHeader viewWithTag:1];
    switch (section) {
        case 0:
            titleSection.text = AMLocalizedString(@"details", @"Label title header of node details").uppercaseString;
            break;
        case 1:
            titleSection.text = AMLocalizedString(@"sharing", @"Label title header of node sharing").uppercaseString;
            break;
        case 2:
            titleSection.text = AMLocalizedString(@"versions", @"Label title header of node versions").uppercaseString;
            break;
        default:
            break;
    }
    return sectionHeader;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UITableViewCell *sectionFooter = [self.tableView dequeueReusableCellWithIdentifier:@"nodeInfoFooter"];

    return sectionFooter;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@", indexPath);
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 1: {
                    CloudDriveTableViewController *cdvc = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
                    [cdvc setParentNode:[[MEGASdkManager sharedMEGASdk] parentNodeForNode:self.node]];
                    [self.navigationController pushViewController:cdvc animated:YES];
                    break;
                }
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    if (self.node.isFolder) {
                        if (self.node.isShared) {
                            ContactsViewController *contactsVC =  [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
                            contactsVC.contactsMode = ContactsModeFolderSharedWith;
                            contactsVC.node = self.node;
                            [self.navigationController pushViewController:contactsVC animated:YES];
                        } else {
                            UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[self.node] sender:self.thumbnailImageView];
                            [self presentViewController:activityVC animated:YES completion:nil];
                        }
                    } else {
                        [self showManageLinkView];
                    }
                    break;
                case 1:
                    [self showManageLinkView];
                    break;
                default:
                    break;
            }
        case 2:
            //TODO: show versions view
            break;
        default:
            break;
    }
}

#pragma mark - TableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.nodeProperties.count;
    } else if (section == 1) {
        if (self.node.type == MEGANodeTypeFolder) {
            return 2;
        } else {
            return 1;
        }
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NodePropertyTableViewCell *propertyCell = [self.tableView dequeueReusableCellWithIdentifier:@"nodePropertyCell" forIndexPath:indexPath];
        propertyCell.keyLabel.text = [self.nodeProperties objectAtIndex:indexPath.row].title;
        propertyCell.valueLabel.text = [self.nodeProperties objectAtIndex:indexPath.row].value;
        if (indexPath.row == 1) {
            propertyCell.valueLabel.textColor = [UIColor mnz_green00BFA5];
        }
        return propertyCell;
    } else if (indexPath.section == 1) {
        if (self.node.isFolder) {
            if (indexPath.row == 0) {
                return [self sharedFolderCellForIndexPath:indexPath];
            } else {
                return [self linkCellForIndexPath:indexPath];
            }
        } else {
            return [self linkCellForIndexPath:indexPath];
        }
    } else {
        return [self versionCellForIndexPath:indexPath];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int sections = 2;
    if (self.node.hasVersions) {
        sections++;
    }
    return sections;
}

#pragma mark - Actions

- (IBAction)closeTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    
    CustomActionViewController *actionController = [[CustomActionViewController alloc] init];
    actionController.node = self.node;
    actionController.displayMode = DisplayModeNodeInfo;
    actionController.actionDelegate = self;
    actionController.actionSender = sender;
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        actionController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popController = [actionController popoverPresentationController];
        popController.delegate = actionController;
        popController.sourceView = sender;
        popController.sourceRect = CGRectMake(0, 0, sender.frame.size.width/2, sender.frame.size.height/2);
    } else {
        actionController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    [self presentViewController:actionController animated:YES completion:nil];
}

#pragma mark - Private

- (NSArray<MegaNodeProperty *> *)nodePropertyCells {
    NSMutableArray<MegaNodeProperty *> *propertiesNode = [NSMutableArray new];
    
    [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"totalSize", @"Size of the file or folder you are sharing") value:[Helper sizeForNode:self.node api:[MEGASdkManager sharedMEGASdk]]]];
    [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"location", @"Title label of a node property.") value:[NSString stringWithFormat:@"%@", [[MEGASdkManager sharedMEGASdk] parentNodeForNode:self.node].name]]];
    if (self.node.type == MEGANodeTypeFolder) {
        if (self.node.isShared) {
            [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"type", @"Refers to the type of a file or folder.") value:AMLocalizedString(@"sharedFolder", @"Title of the incoming shared folders of a user in singular.")]];
        }  else if ([[MEGASdkManager sharedMEGASdk] numberChildFoldersForParent:self.node] + [[MEGASdkManager sharedMEGASdk] numberChildFoldersForParent:self.node] == 0){
            [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"type", @"Refers to the type of a file or folder.") value:AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files")]];
        } else {
            [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"type", @"Refers to the type of a file or folder.") value:AMLocalizedString(@"folder", nil)]];
        }
    } else {
        [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"type", @"Refers to the type of a file or folder.") value:@"de donde saco el tipo de archivo"]];
    }
    [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"created", @"The label of the folder creation time.") value:[Helper dateWithISO8601FormatOfRawTime:self.node.creationTime.timeIntervalSince1970]]];
    if (!self.node.isFolder) {
        [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"modified", @"A label for any 'Modified' text or title.") value:[Helper dateWithISO8601FormatOfRawTime:self.node.modificationTime.timeIntervalSince1970]]];
    }
    if (self.node.type == MEGANodeTypeFolder) {
        [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"contains", @"Label for what a selection contains.") value:[Helper filesAndFoldersInFolderNode:self.node api:[MEGASdkManager sharedMEGASdk]]]];
    }
    
    return [propertiesNode copy];
}

- (NodeTappablePropertyTableViewCell *)versionCellForIndexPath:(NSIndexPath *)indexPath {
    NodeTappablePropertyTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeTappablePropertyCell" forIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:@"versions"];
    cell.titleLabel.text = [AMLocalizedString(@"xVersions", @"Message to display the number of historical versions of files.") stringByReplacingOccurrencesOfString:@"[X]" withString: [NSString stringWithFormat:@"%ld",(long)[self.node numberOfVersions]]];
    return cell;
}

- (NodeTappablePropertyTableViewCell *)sharedFolderCellForIndexPath:(NSIndexPath *)indexPath {
    NodeTappablePropertyTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeTappablePropertyCell" forIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:@"share"];
    if (self.node.isShared) {
        cell.titleLabel.text = AMLocalizedString(@"sharedWidth", @"Label title indicating the number of users having a node shared");
        NSString *usersString = [self outSharesForNode:self.node].count > 1 ? AMLocalizedString(@"users", @"used for example when a folder is shared with 2 or more users") : AMLocalizedString(@"user", @"user (singular) label indicating is receiving some info");
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%lu %@",(unsigned long)[self outSharesForNode:self.node].count, usersString];
        [cell.subtitleLabel setHidden:NO];
    } else {
        cell.titleLabel.text = AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected");
    }
    return cell;
}

- (NodeTappablePropertyTableViewCell *)linkCellForIndexPath:(NSIndexPath *)indexPath {
    NodeTappablePropertyTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeTappablePropertyCell" forIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:@"link"];
    if (self.node.isExported) {
        [[MEGASdkManager sharedMEGASdk] exportNode:self.node delegate:self.exportDelegate];
    } else {
        cell.titleLabel.text = AMLocalizedString(@"getLink", @"Title shown under the action that allows you to get a link to file or folder");
    }
    if (self.node.isFolder && indexPath.row == 1) {
        [cell.separatorView setHidden:YES];
    } else {
        [cell.separatorView setHidden:YES];
    }
    return cell;
}

- (NSMutableArray *)outSharesForNode:(MEGANode *)node {
    NSMutableArray *outSharesForNodeMutableArray = [[NSMutableArray alloc] init];
    
    MEGAShareList *outSharesForNodeShareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:node];
    NSUInteger outSharesForNodeCount = [[outSharesForNodeShareList size] unsignedIntegerValue];
    for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
        MEGAShare *share = [outSharesForNodeShareList shareAtIndex:i];
        if ([share user] != nil) {
            [outSharesForNodeMutableArray addObject:share];
        }
    }
    
    return outSharesForNodeMutableArray;
}

- (void)showManageLinkView {
    UINavigationController *getLinkNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"GetLinkNavigationControllerID"];
    GetLinkTableViewController *getLinkTVC = getLinkNavigationController.childViewControllers[0];
    getLinkTVC.nodesToExport = @[self.node];
    [self presentViewController:getLinkNavigationController animated:YES completion:nil];
}

- (void)browserWithAction:(BrowserAction)action {
    MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [self presentViewController:navigationController animated:YES completion:nil];
    
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.selectedNodesArray = @[self.node];
    browserVC.browserAction = action;
}

#pragma mark - CustomActionViewControllerDelegate

- (void)performAction:(MegaNodeActionType)action inNode:(MEGANode *)node fromSender:(id)sender{
    switch (action) {
            
        case MegaNodeActionTypeDownload:
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
            [node mnz_downloadNode];
            break;
            
        case MegaNodeActionTypeCopy:
            [self browserWithAction:BrowserActionCopy];
            break;
            
        case MegaNodeActionTypeMove:
            [self browserWithAction:BrowserActionMove];
            break;
            
        case MegaNodeActionTypeRename:
            [node mnz_renameNodeInViewController:self];
            break;
            
        case MegaNodeActionTypeShare: {
            UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[self.node] sender:sender];
            [self presentViewController:activityVC animated:YES completion:nil];
        }
            break;
            
        case MegaNodeActionTypeFileInfo:
            break;
            
        case MegaNodeActionTypeLeaveSharing:
            [node mnz_leaveSharingInViewController:self];
            break;
            
        case MegaNodeActionTypeRemoveLink:
            break;
            
        case MegaNodeActionTypeMoveToRubbishBin:
            [node mnz_moveToTheRubbishBinInViewController:self];
            break;
            
        case MegaNodeActionTypeRemove:
            [node mnz_removeInViewController:self];
            break;
            
        case MegaNodeActionTypeRemoveSharing:
            [node mnz_removeSharing];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    self.node = [nodeList nodeAtIndex:0];
    
    [self reloadUI];
}

@end
