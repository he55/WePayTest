#import "WeChat.h"
#import "WPConfig.h"

%hook NewSettingViewController

- (void)reloadTableData {
    %orig;

    WCTableViewSectionManager *section = [%c(WCTableViewSectionManager) sectionInfoDefaut];
    BOOL serviceEnable = [WPConfig sharedConfig].serviceEnable;

    [section addCell:[%c(WCTableViewCellManager) switchCellForSel:@selector(switchServiceEnable:) target:self title:@"WePay" on:serviceEnable]];

    WCTableViewCellManager *cell = serviceEnable ?
        [%c(WCTableViewCellManager) normalCellForSel:@selector(settingServiceURL) target:self title:@"地址" rightValue:[WPConfig sharedConfig].serviceURL] :
        [%c(WCTableViewNormalCellManager) normalCellForTitle:@"地址" rightValue:[WPConfig sharedConfig].serviceURL];
    [section addCell:cell];

    [section addCell:[%c(WCTableViewCellManager) normalCellForSel:@selector(showGitHub) target:self title:@"GitHub" rightValue:@"Star ★"]];

    WCTableViewManager *tableViewMgr = [self valueForKey:@"m_tableViewMgr"];
    [tableViewMgr insertSection:section At:4];
    [[tableViewMgr getTableView] reloadData];
}

%new
- (void)switchServiceEnable:(UISwitch *)sw {
    [WPConfig sharedConfig].serviceEnable = sw.on;
    [self reloadTableData];
}

%new
- (void)settingServiceURL {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"设置订单服务地址" preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入订单服务地址";
        textField.text = [WPConfig sharedConfig].serviceURL;
        textField.keyboardType = UIKeyboardTypeURL;
    }];

    UIAlertAction *okAlertAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [WPConfig sharedConfig].serviceURL = alertController.textFields[0].text;
        [self reloadTableData];
    }];

    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:okAlertAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

%new
- (void)showGitHub {
    NSURL *gitHubUrl = [NSURL URLWithString:@"https://github.com/he55"];
    MMWebViewController *webViewController = [[%c(MMWebViewController) alloc] initWithURL:gitHubUrl presentModal:NO extraInfo:nil];
    [self.navigationController PushViewController:webViewController animated:YES];
}

%end
