
## Sabycom SDK for iOS

  

Полную инструкцию по настройке канала связи, получению идентификатора канала и подключению виджета в приложении можно найти [здесь](https://sbis.ru/help/another/helpdesk/set_channel/mobile)

  

### Технические требования

Sabycom SDK поддерживает устройства с версией iOS 12.2 и выше. Для сборки приложения потребуется IDE Xcode 13

  

### Структура проекта:

  

* ****ios-sabycom-demo**** - Пример реализации приложения с использованием SDK

* ****ios-sabycom-sdk**** - Исходный код SDK

  

### Как настроить

Для подключения SDK мы рекомендуем использовать Cocoapods. Добавьте в файл Podfile зависимость:

  

1. Подключите Sabycom SDK одним из способов:

* через Cocoapods:

    a. добавьте в Podfile зависимость Sabycom SDK:

  
    ```
    target: YourTargetName do
        pod 'Sabycom'
    end
    ```
    
    b. запустите команду «pod install»;

 * через Swift Package Manager:

    a. в IDE Xcode перейдите в менеджер зависимостей Swift Package Manager;

    b. добавьте адрес репозитория SDK: https://github.com/saby/ios-sabycom.

 * Импортируйте модуль Sabycom в ваш UIApplicationDelegate
    ```
    import Sabycom
    ```

 * Сконфигурируйте виджет Sabycom:
a. в метод «didFinishLaunchingWithOptions» добавьте инициализацию виджета; 
b. в параметрах вызова (appId) укажите идентификатор приложения или вставьте  [код, полученный при подключении канала](https://sbis.ru/help/another/helpdesk/set_channel/external_channel?block_open=spoiler11#mobile).
    ```
    Sabycom.initialize(appId: appId) 
    ```

4. Зарегистрируйте объект с данными пользователей:

 * если приложение работает в авторизованном режиме, в качестве userId укажите идентификатор пользователя приложения, чтобы сохранить переписку с оператором при повторной авторизации:
      ```
    let user = SabycomUser(uuid: userId,
                           name: "Имя",
                          surname: "Фамилия",
                            email: "email@google.com",
                            phone: "79001234567")
      Sabycom.registerUser(user)
   ```
    
 *   если ваше приложение поддерживает работу в неавторизованном режиме, пользователь не определен — зарегистрируйте анонимного пользователя:
     ```
     Sabycom.registerAnonymousUser()
     ```
    

        **Пример**
        ```
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
             if loggedIn {
                 let user = SabycomUser(uuid: userId,
                                        name: "Имя",
                                     surname: "Фамилия",
                                       email: "email@google.com",
                                       phone: "79001234567")

                 Sabycom.registerUser(user)
            } else {
                 Sabycom.registerAnonymousUser()
            }
        }
        ```
5. Добавьте вызов виджета в контроллере UIViewController.
    Показать виджет:
    ```
    Sabycom.show()
    ```
    Скрыть виджет:
    ```
    Sabycom.hide()
    ```
    **Пример**
    
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
             Sabycom.show(on: self)
         }
    
         @objc func onHideSabycom(_ sender: Any) {
             Sabycom.hide()
         }
     }
     ```
  
6. Чтобы получить количество непрочитанных сообщений, используйте свойство Sabycom.unreadConversationCount и подпишитесь на обновления с помощью NotificationCenter.
    
    **Пример**
    
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
             unreadMessagesLabel.text = "\(Sabycom.unreadConversationCount)"
         }
    }
    ```

7. Настройте отправку пуш-уведомлений об ответе оператора.
    Чтобы пользователи получали уведомления от Sabycom, запросите разрешение на отправку и зарегистрируйте токен устройства в AppDelegate.
    
    Получать уведомления в debug-режиме:
    
    ```
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var tokenType = SabycomAPNSTokenType.prod
        #if DEBUG
            tokenType = .sandbox
        #endif
        Sabycom.registerForPushNotifications(with: deviceToken, tokenType: tokenType)
    }
    ```
    
    Показать уведомление о новом сообщении:
    
    ```
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        // Проверяет, пришел пуш от Sabycom или от другого сервиса
        if Sabycom.isSabycomPushNotification(info: userInfo), 
        let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window, let controller = window.rootViewController {
            // Показывает всплывающее уведомление с новым сообщением. parentView - view, в котором нужно показать уведомление
            Sabycom.handlePushNotification(info: userInfo, parentView: controller.view)
        }
        completionHandler([])
     }
    ```
    
    Отписаться от уведомлений:
    
    ```
    Sabycom.logout()
    ```
