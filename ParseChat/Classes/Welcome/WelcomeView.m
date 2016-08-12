//
// Copyright (c) 2015 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Parse/Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <ParseTwitterUtils/ParseTwitterUtils.h>
#import "ProgressHUD.h"
#import "UIImageView+WebCache.h"

#import "utilities.h"

#import "WelcomeView.h"
#import "LoginView.h"
#import "RegisterView.h"

@implementation WelcomeView

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	self.title = @"Welcome";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
	[self.navigationItem setBackBarButtonItem:backButton];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionRegister:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RegisterView *registerView = [[RegisterView alloc] init];
	[self.navigationController pushViewController:registerView animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionLogin:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	LoginView *loginView = [[LoginView alloc] init];
	[self.navigationController pushViewController:loginView animated:YES];
}

#pragma mark - Twitter login methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionTwitter:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[ProgressHUD show:@"Signing in..." Interaction:NO];
	[PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error)
	{
		if (user != nil)
		{
			if (user[PF_USER_TWITTERID] == nil)
			{
				[self processTwitter:user];
			}
			else [self userLoggedIn:user];
		}
		else [ProgressHUD showError:@"Twitter login error."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)processTwitter:(PFUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	PF_Twitter *twitter = [PFTwitterUtils twitter];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	user[PF_USER_FULLNAME] = twitter.screenName;
	user[PF_USER_FULLNAME_LOWER] = [twitter.screenName lowercaseString];
	user[PF_USER_TWITTERID] = twitter.userId;
	[user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error != nil)
		{
			[PFUser logOut];
			[ProgressHUD showError:error.userInfo[@"error"]];
		}
		else [self userLoggedIn:user];
	}];
}

#pragma mark - Facebook login methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionFacebook:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[ProgressHUD show:@"Signing in..." Interaction:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *permissionsArray = @[@"public_profile", @"email", @"user_friends", @"user_photos"];
	[PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error)
	{
		if (user != nil)
		{
//			if (user[PF_USER_FACEBOOKID] == nil)
//			{
				[self requestFacebook:user];
//			}
//			else [self userLoggedIn:user];
		}
		else [ProgressHUD showError:@"Facebook login error."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)requestFacebook:(PFUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    // [FBRequestConnection startWithGraphPath:@"me" parameters:[NSDictionary dictionaryWithObject:@"cover,picture.type(large),id,name,first_name,last_name,gender,birthday,email,location,hometown,bio,photos" forKey:@"fields"] HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
	FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name, email, photos, albums"}];
	[request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error)
	{
		if (error == nil)
		{
			NSDictionary *userData = (NSDictionary *)result;
			[self requestFacebookUserPicture:user UserData:userData];   //上傳用戶的照片
		}
		else
		{
			[PFUser logOut];
			[ProgressHUD showError:@"Failed to fetch Facebook user data."];
		}
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)requestFacebookUserPicture:(PFUser *)user UserData:(NSDictionary *)userData
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *link = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", userData[@"id"]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	SDWebImageManager *manager = [SDWebImageManager sharedManager];
	[manager downloadImageWithURL:[NSURL URLWithString:link] options:0 progress:nil
	completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL)
	{
		if (image != nil)
		{
			[self processFacebook:user UserData:userData Image:image];
		}
		else
		{
			[PFUser logOut];
			[ProgressHUD showError:@"Failed to fetch Facebook profile picture."];
		}
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)processFacebook:(PFUser *)user UserData:(NSDictionary *)userData Image:(UIImage *)image
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIImage *picture = ResizeImage(image, 140, 140, 1);
	UIImage *thumbnail = ResizeImage(image, 60, 60, 1);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(picture, 0.6)];
	[filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error != nil) NSLog(@"WelcomeView processFacebook picture save error.");
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	PFFile *fileThumbnail = [PFFile fileWithName:@"thumbnail.jpg" data:UIImageJPEGRepresentation(thumbnail, 0.6)];
	[fileThumbnail saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error != nil) NSLog(@"WelcomeView processFacebook thumbnail save error.");
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *name = userData[@"name"];
	NSString *email = userData[@"email"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (name == nil) name = @"";
	if (email == nil) email = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	user[PF_USER_EMAILCOPY] = email;
	user[PF_USER_FULLNAME] = name;
	user[PF_USER_FULLNAME_LOWER] = [name lowercaseString];
	user[PF_USER_FACEBOOKID] = userData[@"id"];
	user[PF_USER_PICTURE] = filePicture;
	user[PF_USER_THUMBNAIL] = fileThumbnail;
	[user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error != nil)
		{
			[PFUser logOut];
			[ProgressHUD showError:error.userInfo[@"error"]];
		}
		else
        {
            [self userLoggedIn:user];
            [self requestFacebookPhotos:user UserData:userData];
        }
	}];
}

#pragma mark - Helper methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)userLoggedIn:(PFUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	ParsePushUserAssign();
	PostNotification(NOTIFICATION_USER_LOGGED_IN);
	[ProgressHUD showSuccess:[NSString stringWithFormat:@"Welcome back %@!", user[PF_USER_FULLNAME]]];
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 背景上傳照片

- (void)requestFacebookPhotos:(PFUser *)user UserData:(NSDictionary *)userData
{
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/photos" parameters:@{@"fields": @"picture, images, photo"}];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error)
     {
//         NSLog(@"result = %@", result);
         // result[@"data"][0][@"images"][0][@"source"]
         // result[@"data"][0][@"id"]
         
         for (int i=0; i<[result[@"data"] count]; i++) {
             NSLog(@"source = %@", result[@"data"][i][@"images"][0][@"source"]);
             
             NSString *link = result[@"data"][i][@"images"][0][@"source"];
             
             //確認 photo id 有沒有重複
             PFQuery *photoQuery = [PFQuery queryWithClassName:PF_PHOTOS_CLASS_NAME];
             [photoQuery whereKey:PF_PHOTOS_ID equalTo:result[@"data"][i][@"id"]];
             [photoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                 if (error) {
                     
                     //---------------------------------------------------------------------------------------------------------------------------------------------
                     SDWebImageManager *manager = [SDWebImageManager sharedManager];
                     [manager downloadImageWithURL:[NSURL URLWithString:link] options:0 progress:nil
                                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL)
                      {
                          if (image != nil)
                          {
                              PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(image, 0.6)];
                              [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                               {
                                   if (error != nil) NSLog(@"WelcomeView processFacebook picture save error.");
                               }];
                              
                              PFObject *photoObject = [PFObject objectWithClassName:PF_PHOTOS_CLASS_NAME];
                              photoObject[PF_PHOTOS_USER] = [PFUser currentUser];
                              photoObject[PF_PHOTOS_SOURCE] = result[@"data"][i][@"images"][0][@"source"];
                              photoObject[PF_PHOTOS_FILE] = filePicture;
                              photoObject[PF_PHOTOS_ID]     = result[@"data"][i][@"id"];
                              [photoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                  if (succeeded) {
                                      
                                  }
                              }];
                          }
                      }];
                 }
             }];
             
             
             
         }
     }];
}


@end
