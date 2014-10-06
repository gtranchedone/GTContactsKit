
Pod::Spec.new do |s|
  s.name             = "GTContactsKit"
  s.version          = "0.1.3"
  s.summary          = "A set of classes for fetching, displaying and selecting contacts from the AddressBook."
  s.description      = <<-DESC
                       A set of classes for fetching, displaying and selecting contacts from the AddressBook. GTContactsPicker lets you fetch the information and GTContactsPickerController lets you display them and select them using different view styles.
                       DESC
  s.homepage         = "https://github.com/gtranchedone/GTContactsKit"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Gianluca Tranchedone" => "gianluca@cocoabeans.me" }
  s.source           = { :git => "https://github.com/gtranchedone/GTContactsKit.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/gtranchedone'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'GTContactsKit' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'AddressBook'
  s.dependency 'VENTokenField', '~> 2.2'
  s.dependency 'GTFoundation', '~> 0.1'
end
