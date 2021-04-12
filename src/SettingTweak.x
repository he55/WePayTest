#import "WeChat.h"
#import "WPConfig.h"

%hook NewSettingViewController

- (void)reloadTableData {
    %orig;

    WCTableViewSectionManager *section1 = [%c(WCTableViewSectionManager) sectionInfoDefaut];
    BOOL serviceEnable = [WPConfig sharedConfig].serviceEnable;
    [section1 addCell:[%c(WCTableViewCellManager) switchCellForSel:@selector(switchServiceEnable:) target:self title:@"启用 WePay" on:serviceEnable]];

    WCTableViewCellManager *cell = serviceEnable ?
        [%c(WCTableViewCellManager) normalCellForSel:@selector(settingDelay) target:self title:@"地址" rightValue:[WPConfig sharedConfig].serviceURL] :
        [%c(WCTableViewNormalCellManager) normalCellForTitle:@"地址" rightValue:[WPConfig sharedConfig].serviceURL];
    [section1 addCell:cell];

    [section1 addCell:[%c(WCTableViewCellManager) normalCellForSel:@selector(showGithub) target:self title:@"我的 GitHub" rightValue:@"★ star"]];

    WCTableViewManager *m_tableViewMgr = [self valueForKey:@"m_tableViewMgr"];
    [m_tableViewMgr insertSection:section1 At:4];
    [[m_tableViewMgr getTableView] reloadData];
}

%new
- (void)switchServiceEnable:(UISwitch *)sw {
    [WPConfig sharedConfig].serviceEnable = sw.on;
    WCTableViewManager *m_tableViewMgr = [self valueForKey:@"m_tableViewMgr"];
    [[m_tableViewMgr getTableView] reloadData];
}

%new
- (void)showGithub {
    NSURL *url = [NSURL URLWithString:@"https://github.com/he55?tab=stars"];
    MMWebViewController *webViewController = [[%c(MMWebViewController) alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [self.navigationController PushViewController:webViewController animated:YES];
}

%end
