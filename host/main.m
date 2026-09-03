// AutoClicker 宿主 App —— 仅负责加载内嵌的 AutoClicker.dylib
// 巨魔(TrollStore)安装后, 启动即加载 dylib, 由 dylib 在构造器中建立悬浮控制面板。
#import <UIKit/UIKit.h>
#import <dlfcn.h>

@interface HostVC : UIViewController
@end
@implementation HostVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    UILabel *lab = [[UILabel alloc] init];
    lab.text = @"AutoClicker 宿主\n\n若未出现悬浮控制面板, 请确认:\n1. 宿主 App 已带 get-properties 授权\n2. dylib 已成功加载";
    lab.numberOfLines = 0;
    lab.textAlignment = NSTextAlignmentCenter;
    lab.textColor = [UIColor labelColor];
    lab.font = [UIFont systemFontOfSize:15];
    lab.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:lab];
    [NSLayoutConstraint activateConstraints:@[
        [lab.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [lab.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [lab.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
        [lab.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],
    ]];
}
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[HostVC alloc] init];
    [self.window makeKeyAndVisible];
    // 窗口已就绪后再加载 dylib, 让构造器能拿到 keyWindow 建立浮窗
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AutoClicker" ofType:@"dylib"];
    if (path) {
        void *h = dlopen(path.UTF8String, RTLD_NOW);
        if (!h) {
            NSLog(@"[ACHost] 加载 AutoClicker.dylib 失败: %s", dlerror());
        } else {
            NSLog(@"[ACHost] 已加载 AutoClicker.dylib");
        }
    } else {
        NSLog(@"[ACHost] 未找到内嵌的 AutoClicker.dylib");
    }
    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
