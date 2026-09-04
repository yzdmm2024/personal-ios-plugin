// AutoClicker 宿主 App —— 仅负责加载内嵌的 AutoClicker.dylib
// 设计原则: 先稳定显示界面, 再延迟加载 dylib, 并把加载结果/错误显示在屏幕上,
// 便于区分"宿主起不来"还是"dylib 加载崩"。
#import <UIKit/UIKit.h>
#import <dlfcn.h>

@interface HostVC : UIViewController
@property (nonatomic, strong) UILabel *lab;
@end
@implementation HostVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    _lab = [[UILabel alloc] init];
    _lab.numberOfLines = 0;
    _lab.textAlignment = NSTextAlignmentCenter;
    _lab.textColor = [UIColor labelColor];
    _lab.font = [UIFont systemFontOfSize:15];
    _lab.text = @"AutoClicker 宿主\n\n正在加载连点器…";
    _lab.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_lab];
    [NSLayoutConstraint activateConstraints:@[
        [_lab.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_lab.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_lab.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
        [_lab.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],
    ]];
}
- (void)setStatus:(NSString *)s {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lab.text = s;
    });
}
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) HostVC *vc;
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.vc = [[HostVC alloc] init];
    self.window.rootViewController = self.vc;
    [self.window makeKeyAndVisible];
    // 延迟 1.5s 再加载 dylib: 保证宿主界面已稳定显示,
    // 若之后崩溃, 可确认是 dylib 而非宿主/签名问题。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self loadDylib];
    });
    return YES;
}
- (void)loadDylib {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AutoClicker" ofType:@"dylib"];
    if (!path) {
        [self.vc setStatus:@"AutoClicker 宿主\n\n错误: 未找到内嵌的 AutoClicker.dylib"];
        return;
    }
    void *h = dlopen(path.UTF8String, RTLD_NOW);
    if (!h) {
        const char *err = dlerror();
        NSString *msg = [NSString stringWithFormat:@"AutoClicker 宿主\n\ndylib 加载失败:\n%s", err ? err : "(无错误信息)"];
        [self.vc setStatus:msg];
        return;
    }
    [self.vc setStatus:@"AutoClicker 宿主\n\ndylib 已加载\n(若出现连点器浮窗即成功)"];
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
