#import <UIKit/UIKit.h>

typedef id CDUnknownBlockType;

#pragma mark -

@interface WCPayTransferGetFixedAmountQRCodeResponse : NSObject
@property (nonatomic, assign) unsigned int qrcode_level;
@property (nonatomic, copy) NSString *m_nsFixedAmountQRCode;
@end

@interface WCPayControlData : NSObject
@property (nonatomic, assign) int fixed_qrcode_level;
@property (nonatomic, assign) int m_enWCPayFacingReceiveMoneyScene;
@property (nonatomic, copy) NSString *m_nsFixedAmountReceiveMoneyQRCode;
@end

@interface WCBaseControlLogic : NSObject
- (id)getCurrentViewController;
- (void)dismissCurrentViewWithAnimated:(_Bool)arg1;
@end

@interface WCBizControlLogic : WCBaseControlLogic
- (void)stopLoading;
- (void)startLoading;
@end

@interface WCPayControlLogic : WCBizControlLogic
{
    WCPayControlData *m_data;
}

- (_Bool)onError:(id)arg1;
@end

@interface WCPayFacingReceiveContorlLogic : WCPayControlLogic
- (void)startLogic;
- (id)initWithData:(id)arg1;
- (void)OnGetFixedAmountQRCode:(WCPayTransferGetFixedAmountQRCodeResponse *)arg1 Error:(id)arg2;
- (void)WCPayFacingReceiveFixedAmountViewControllerNext:(NSString *)arg1 Description:(NSString *)arg2;
- (void)WCPayFacingReceiveChangeToUnFixedAmount;
- (void)WCPayFacingReceiveChangeToFixedAmount;
@end


#pragma mark -

@interface WCTableViewManager : NSObject
- (void)clearAllSection;
- (void)insertSection:(id)arg1 At:(unsigned int)arg2;
- (void)addSection:(id)arg1;
- (id)getTableView;
@end

@interface WCTableViewSectionManager : NSObject
+ (id)sectionInfoHeader:(id)arg1 Footer:(id)arg2;
+ (id)sectionInfoFooter:(id)arg1;
+ (id)sectionInfoHeader:(id)arg1;
+ (id)sectionInfoDefaut;
- (void)addCell:(id)arg1;
@end

@interface WCTableViewCellManager : NSObject
+ (id)switchCellForSel:(SEL)arg1 target:(id)arg2 title:(id)arg3 on:(_Bool)arg4;
+ (id)normalCellForSel:(SEL)arg1 target:(id)arg2 title:(id)arg3 rightValue:(id)arg4 canRightValueCopy:(_Bool)arg5;
+ (id)normalCellForSel:(SEL)arg1 target:(id)arg2 title:(id)arg3 rightValue:(id)arg4;
+ (id)normalCellForSel:(SEL)arg1 target:(id)arg2 title:(id)arg3;
@end

@interface WCTableViewNormalCellManager : WCTableViewCellManager
+ (id)normalCellForTitle:(id)arg1 rightValue:(id)arg2;
@end

@interface MMWebViewController : UIViewController
- (id)initWithURL:(id)arg1 presentModal:(_Bool)arg2 extraInfo:(id)arg3;
@end

@interface UINavigationController (WeChat)
- (void)PushViewController:(id)arg1 animated:(_Bool)arg2 completion:(CDUnknownBlockType)arg3;
- (void)PushViewController:(id)arg1 animated:(_Bool)arg2;
@end


#pragma mark -

@interface WCPayFacingReceiveQRCodeViewController : UIViewController
- (void)refreshViewWithData:(id)arg1;
@end

@interface NewMainFrameViewController : UIViewController
- (void)openFace2FaceReceiveMoney;
- (void)showQRInfoView;
@end

@interface ContactsViewController : UIViewController
@end

@interface NewSettingViewController : UIViewController
{
    WCTableViewManager *m_tableViewMgr;
}

- (void)reloadTableData;
@end


#pragma mark -

@interface MMContext : NSObject
+ (id)currentUserLibraryCachePath;
+ (id)currentUserDocumentPath;
+ (id)currentUserMd5;
+ (id)currentUserName;
+ (const char *)currentUinStrForLog;
+ (unsigned int)currentUin;
+ (id)activeUserContext;
+ (id)rootContext;
+ (id)lastContext;
+ (id)fastCurrentContext;
+ (id)currentContext;
- (id)userLibraryCachePath;
- (id)userDocumentPath;
- (id)userMd5;
- (id)userName;
- (unsigned int)uin;
- (_Bool)isServiceExist:(Class)arg1;
- (id)getService:(Class)arg1;
@end

@interface WCUIAlertView : NSObject
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 handler:(CDUnknownBlockType)arg4 btnTitle:(id)arg5 handler:(CDUnknownBlockType)arg6 btnTitle:(id)arg7 handler:(CDUnknownBlockType)arg8;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 handler:(CDUnknownBlockType)arg4 btnTitle:(id)arg5 handler:(CDUnknownBlockType)arg6;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 handler:(CDUnknownBlockType)arg4;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 btnTitle:(id)arg6 target:(id)arg7 sel:(SEL)arg8 btnTitle:(id)arg9 target:(id)arg10 sel:(SEL)arg11 view:(id)arg12;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 view:(id)arg6;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 cancelBtnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 btnTitle:(id)arg6 target:(id)arg7 sel:(SEL)arg8 view:(id)arg9;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 btnTitle:(id)arg6 target:(id)arg7 sel:(SEL)arg8 view:(id)arg9;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 destructiveBtnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 cancelBtnTitle:(id)arg6 target:(id)arg7 sel:(SEL)arg8 view:(id)arg9;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 btnTitle:(id)arg6 target:(id)arg7 sel:(SEL)arg8 rightBtnStyle:(long long)arg9 view:(id)arg10 forbidDarkMode:(_Bool)arg11;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 btnTitle:(id)arg6 target:(id)arg7 sel:(SEL)arg8 rightBtnStyle:(long long)arg9 view:(id)arg10;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 btnTitle:(id)arg6 target:(id)arg7 sel:(SEL)arg8 btnTitle:(id)arg9 target:(id)arg10 sel:(SEL)arg11;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 btnTitle:(id)arg6 target:(id)arg7 sel:(SEL)arg8;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 btnTitle:(id)arg3;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2;
+ (id)showAlertWithTitle:(id)arg1 message:(id)arg2 cancelBtnTitle:(id)arg3 target:(id)arg4 sel:(SEL)arg5 btnTitle:(id)arg6 target:(id)arg7 sel:(SEL)arg8;
@end

@interface CAppViewControllerManager : NSObject
+ (id)getTabBarController;
+ (CAppViewControllerManager *)getAppViewControllerManager;
+ (_Bool)hasEnterWechatMain;
- (_Bool)isNowInRootViewController;
- (unsigned int)getCurTabBarIndex;
- (id)getTopViewController;
- (unsigned int)getAppIconTotalUnReadCount;
- (NewMainFrameViewController *)getNewMainFrameViewController;
- (id)getMainWindowViewController;
@end
