## Sabycom SDK for iOS 

### Требования
Для работы Sabycom SDK необходим iOS версии 12.2 и выше и Xcode 13.0 или выше.

### Подключение
Для подключения SDK мы рекомендуем использовать Cocoapods. Добавьте в файл Podfile зависимость:

```
pod 'Sabycom'
```
### Структура проекта:

* **ios-sabycom-demo** - Пример реализации приложения с использованием SDK
* **ios-sabycom-sdk** - Исходный код SDK


### Использование SDK:

1. Импортируйте модуль Sabycom в ваш UIApplicationDelegate
```
import Sabycom
```
2. Сконфигурируйте Sabycom, в параметрах вызова укажите идентификатор приложения или вставьте готовый код, полученный при подключении канала 

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    SabycomSDK.initialize(appId: appId)
}
 ```

3. В зависимости от того, есть в вашем приложении авторизация или нет, зарегистрируйте пользователя или анонимного пользователя

 ```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if loggedIn {
        let user = SabycomUser(uuid: userId,
                       name: "Имя",
                       surname: "Фамилия",
                       email: "email@google.com",
                       phone: "79001234567")

        SabycomSDK.registerUser(user)
    } else {
        SabycomSDK.registerAnonymousUser()
    }
}
 ```

4. Чтобы показать виджет, вызовите в вашем UIViewController SabycomSDK.show(). Чтобы скрыть виджет, вызовите SabycomSDK.hide()

 ```
 import Sabycom

 class YourViewController: UIViewController {
    func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton()
        // ...
        button.addTarget(self, action: #selector(onSabycom(_:)), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc func onSabycom(_ sender: Any) {
        SabycomSDK.show(on: self)
    }

    @objc func onHideSabycom(_ sender: Any) {
        SabycomSDK.hide()
    }
 }
 ```


5. Для получения количества непрочитанных сообщений используйте свойство SabycomSDK.unreadConversationCount и подпишитесь на обновления, используя NotificationCenter

```

import Sabycom
class YourViewController: UIViewController {
   private var unreadMessagesLabel: UILabel!

   func viewDidLoad() {
       super.viewDidLoad()

       unreadMessagesLabel = UILabel()
       // ...
       view.addSubview(unreadMessagesLabel)

       NotificationCenter.default.addObserver(
            forName: .SabycomUnreadConversationCountDidChange,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.updateUnreadMessagesLabel()
            }
        updateUnreadMessagesLabel()
   }

   func updateUnreadMessagesLabel() {
       unreadMessagesLabel.text = "\(SabycomSDK.unreadConversationCount)"
   }
}

```

6. Чтобы ваши пользователи смогли получать Push-уведомления от Sabycom, вы должны [запросить разрешение](https://developer.apple.com/documentation/usernotifications/asking_permission_to_use_notifications) на отправку Push-уведомлений и зарегистрировать токен устройства в AppDelegate. Чтобы иметь возможность получать уведомления в debug режиме, передайте тип токена sandbox

```
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var tokenType = SabycomAPNSTokenType.prod
        
        #if DEBUG
            tokenType = .sandbox
        #endif
        
        SabycomSDK.registerForPushNotifications(with: deviceToken, tokenType: tokenType)
    }
```

7. Чтобы удалить информацию о пользователе и отписаться от уведомлений, вызовите функцию
```
SabycomSDK.logout()
```

8. Для того, чтобы показать всплывающее уведомление о новом сообщении, вызовите следующие функции

```
public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Проверяет, пришел пуш от Sabycom или от другого сервиса
        if SabycomSDK.isSabycomPushNotification(info: userInfo), 
            let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window, let controller = window.rootViewController {

            // Показывает всплывающее уведомление с новым сообщением. parentView - view, в котором нужно показать уведомление
            SabycomSDK.handlePushNotification(info: userInfo, parentView: controller.view)
        }
        
        completionHandler([])
    }
```

