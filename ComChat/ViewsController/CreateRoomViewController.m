//
//  CreateGroupViewController.m
//  ComChat
//
//  Created by D404 on 15/6/5.
//  Copyright (c) 2015年 D404. All rights reserved.
//

#import "CreateRoomViewController.h"
#import "UIViewAdditions.h"
#import "XMPPManager.h"
#import "UIView+Toast.h"
#import <MBProgressHUD.h>
#import "InviteUserViewController.h"
#import <ReactiveCocoa.h>

@interface CreateRoomViewController () {
    MBProgressHUD *HUD;
}

@property (nonatomic, strong) UIImageView *roomImage;
@property (nonatomic, strong) UITextField *roomIDField;

@end

@implementation CreateRoomViewController


#pragma mark 初始化风格
- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        
    }
    return self;
}


#pragma mark 初始化界面
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.roomsViewModel = [RoomsViewModel sharedViewModel];
        
        [[XMPPManager sharedManager].xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XMPPManager sharedManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        @weakify(self)
        [self.roomsViewModel.updatedContentSignal subscribeNext:^(id x) {
            @strongify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
        
        
    }
    return self;
}

- (void)dealloc
{
    [[XMPPManager sharedManager].xmppRoom removeDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[XMPPManager sharedManager].xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}


#pragma mark 初始化界面
- (void)loadView
{
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"创建群组";
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(createGroup:)] animated:YES];
    
    /* 为滚动条添加手势 */
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchScrollView)];
    [recognizer setNumberOfTapsRequired:1];
    [recognizer setNumberOfTouchesRequired:1];
    [self.tableView addGestureRecognizer:recognizer];
    
    // 有数据显示分隔线，无数据不显示
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



#pragma mark 申请创建群组
- (IBAction)createGroup:(id)sender
{
    NSLog(@"申请创建群组...");
    if ([self.roomIDField.text isEqualToString:@""]) {
        [self.view makeToast:@"请输入群组名称" duration:1.0 position:CSToastPositionCenter];
        return ;
    }
    [self.roomsViewModel createRoomWithRoomName:self.roomIDField.text];
}


#pragma mark 点击ScrollView，键盘自动消失
- (void)touchScrollView
{
    [_roomIDField resignFirstResponder];
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Table view data source
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* reuseIdentifier  = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.textLabel.centerY = cell.centerY;
    }
    
    switch (indexPath.section) {
        case 0:
        {
            cell.imageView.image = [UIImage imageNamed:@"group_head_default"];
            cell.textLabel.text = @"设置群组头像";
            break;
        }
        case 1:
        {
            // 设置群组输入框
            self.roomIDField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 45)];
            [self.roomIDField setPlaceholder:@"请输入群组名称"];
            self.roomIDField.backgroundColor = [UIColor whiteColor];
            [self.roomIDField setFont:[UIFont systemFontOfSize:14]];
            self.roomIDField.clearButtonMode = UITextFieldViewModeAlways;
            self.roomIDField.delegate = self;
            
            [cell addSubview:self.roomIDField];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
        default:
            break;
    }
    
    return cell;
}



//设置处理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {           //设置群组头像
        [self performSelector:@selector(selectImage:) withObject:nil afterDelay:0];
        
    } else if(indexPath.section == 1) {     //邀请好友
        
    }
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 100.0f;
    }
    return 45.0f;
}


#pragma mark 下面是从本地选择图片模块，设置群组头像
- (IBAction)selectImage:(id)sender {
    UIActionSheet *myActionSheet = [[UIActionSheet alloc]
                                    initWithTitle:@"选择图片"
                                    delegate:self
                                    cancelButtonTitle:@"取消"
                                    destructiveButtonTitle:nil
                                    otherButtonTitles: @"相册", @"相机",nil];
    [myActionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
        {
            //从相册选择
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            //资源类型为图片库
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.delegate = self;
            //设置选择后的图片可被编辑
            picker.allowsEditing = YES;
            [self presentViewController:picker animated:YES completion:^(){
                NSLog(@"从相册选择图片");
            }];
            break;
        }
        case 1:
        {
            //资源类型为照相机
            UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
            //判断是否有相机
            if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]){
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                //设置拍照后的图片可被编辑
                picker.allowsEditing = YES;
                //资源类型为照相机
                picker.sourceType = sourceType;
                [self presentViewController:picker animated:YES completion:^(){
                    NSLog(@"拍照成功！");
                }];
            }else {
                NSLog(@"该设备无摄像头");
            }
            break;
        }
        default:
            break;
    }
}


#pragma Delegate method UIImagePickerControllerDelegate
//图像选取器的委托方法，选完图片后回调该方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    
    //当图片不为空时显示图片并保存图片
    if (image != nil) {
        //图片显示在界面上
        self.roomImage.image = image;
    }
    //关闭相册界面
    [picker dismissViewControllerAnimated:YES completion:^{}];
}



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - XMPPRoomDelegate
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark 创建聊天室成功
- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    NSLog(@"CreateRoomViewController xmppRoom聊天室已创建...,%@", sender);
    [self.view makeToast:@"群组创建成功" duration:1.5 position:CSToastPositionCenter];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark 已经加入群组
- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    NSLog(@"CreateRoomViewController xmppRoom已经加入群组, %@", sender);
}



@end
