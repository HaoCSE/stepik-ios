# Uncomment this line to define a global platform for your project
platform :ios, '8.0'
source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def all_pods
    pod 'Alamofire'
    pod 'SwiftyJSON'
    pod 'SDWebImage'
    pod 'TextFieldEffects'
    pod "DownloadButton"
    pod 'SVProgressHUD'
    pod 'FLKAutoLayout', '0.2.1'
    pod 'TSMessages', :git => 'https://github.com/KrauseFx/TSMessages.git'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'DZNEmptyDataSet'
    pod 'AFImageHelper'
    pod 'Firebase/Messaging'
    pod 'Firebase/AppIndexing'
    pod "MagicalRecord"
    pod 'AAShareBubbles'
    pod 'BEMCheckBox'
    pod 'IQKeyboardManagerSwift'
    pod 'Kanna', '1.0.6'
    pod 'CRToast'
    pod 'TUSafariActivity', '~> 1.0'
end

target 'Stepic' do
    all_pods
    target 'StepicTests' do
        inherit! :search_paths
        all_pods
    end
end

target 'SberbankUniversity' do 
    all_pods
end
