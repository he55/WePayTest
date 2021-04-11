#import <UIKit/UIKit.h>
#import "WeChat.h"
#import "WPConfig.h"

%hook NewSettingViewController

- (void)reloadTableData {
    %orig;

    WCTableViewManager *m_tableViewMgr = [self valueForKey:@"m_tableViewMgr"];

    WCTableViewSectionManager *section1 = [%c(WCTableViewSectionManager) sectionInfoDefaut];
    BOOL serviceEnable = [WPConfig sharedConfig].serviceEnable;
    [section1 addCell:[%c(WCTableViewCellManager) switchCellForSel:@selector(switchRedEnvelop:) target:self title:@"启用 WePay" on:serviceEnable]];

    WCTableViewCellManager *cell = serviceEnable ?
        [%c(WCTableViewCellManager) normalCellForSel:@selector(settingDelay) target:self title:@"地址" rightValue:[WPConfig sharedConfig].serviceURL] :
        [%c(WCTableViewNormalCellManager) normalCellForTitle:@"地址" rightValue:[WPConfig sharedConfig].serviceURL];
    [section1 addCell:cell];

    [section1 addCell:[%c(WCTableViewCellManager) normalCellForSel:@selector(showGithub) target:self title:@"我的 GitHub" rightValue:@"★ star"]];
    [m_tableViewMgr insertSection:section1 At:4];


    WCTableViewSectionManager *section2 = [%c(WCTableViewSectionManager) sectionInfoDefaut];
    [section2 addCell:[%c(WCTableViewCellManager) switchCellForSel:@selector(settingMessageRevoke:) target:self title:@"消息防撤回" on:[WPConfig sharedConfig].messageRevokeEnable]];
    [m_tableViewMgr insertSection:section2 At:4];

    [self reloadData2];
}

%new
- (void)reloadData2 {
    WCTableViewManager *m_tableViewMgr = [self valueForKey:@"m_tableViewMgr"];
    [[m_tableViewMgr getTableView] reloadData];
}

%new
- (void)switchRedEnvelop:(UISwitch *)sw {
    [WPConfig sharedConfig].serviceEnable = sw.on;
    [self reloadData2];
}

%new
- (void)settingMessageRevoke:(UISwitch *)sw {
    [WPConfig sharedConfig].messageRevokeEnable = sw.on;
}

%new
- (void)showGithub {
    NSURL *url = [NSURL URLWithString:@"https://github.com/he55?tab=stars"];
    MMWebViewController *webViewController = [[%c(MMWebViewController) alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [self.navigationController PushViewController:webViewController animated:YES];
}

%end
