# CONFIGURATION 

This document describes some of the more advanced configuration of the [element-ios](https://github.com/vector-im/element-ios) app. General build config settings are found in the [BuildSettings.swift](https://github.com/vector-im/element-ios/blob/develop/Config/BuildSettings.swift) file. 

## Notifications
If you are running your own build of element-ios, you will need to setup a notification server. If this is your first excursion into Apple's Push Notification service (APNs) you probably want to familiarize yourself with some basics [here](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html). In order for your notifications to work your app will need a unique APNs certificate, which is one reason that Matrix/Element doesn't have a server everyone can simply use. 

There a few assumptions going into this:
* you know how to [install and build](./INSTALL.md) elemen-ios
* you have an Apple developer account (for certificates and such)
* you are using [Sygnal](https://github.com/matrix-org/sygnal) for the push gateway server (this is what Matrix uses as of writing)
* you have a homeserver set up, such as matrix [Synapse](https://github.com/matrix-org/synapse).

### Element-ios

Update the [Sygnal url](https://github.com/vector-im/element-ios/blob/develop/Config/BuildSettings.swift#L105) in the build file. Also note, when testing notifications you want to have the build running on a physical device, not in Xcode simulator. Either install it directly or through TestFlight etc.

### APNs Certificates

Log onto your apple developer account. 

1. Under `certificates` choose add new (+) and select **Apple Push Notification service SSL (Sandbox & Production)**.
2. Add your app ID.
3. Upload a certificate signing request. (You can generate this request in your local _Keychain Access_ application, by going to `Certificate Assistant` and choosing `Request a Certificate from a Certificate Authority`; pick whatever name you like and save to disk).
4. Create, download and add the certificate to _Keychain Access_. (Click on the certificate in _Keychain Access_. If you see a `certificate not trusted` in red warning then do the following: from [Apple](https://www.apple.com/certificateauthority/) download and add to your keychain (drop it in there) the [Apple Developer ID Intermediate Certificate (G2)](https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer) and the [Apple Worldwide Developer Relations Intermediate Certificate (G4)](https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer). The red warning should disappear.)
5. Export the certificate into a .p12 file by selecting the certificate + key (2 files) in _Keychain Access_.
6. Convert it to a pem file: `openssl pkcs12 -in ~/Desktop/Certificates.p12 -out apns.pem -nodes -clcerts`. This is the file you will use in the Sygnal server configuration described below.


### Setting up Sygnal

This is a brief overview (but should be complete to get going). For more information see the [Sygnal repo](https://github.com/matrix-org/sygnal).

0. Setup reverse proxy (nginx example). Assuming your Sygnal server URL is as above `https:///[DOMAIN]/_matrix/push/v1/notify` your nginx config will look something like
```
location ~ ^(/_matrix/push/v1/notify) {
        # note: do not add a path (even a single /) after the port in `proxy_pass`,
        # otherwise nginx will canonicalise the URI and cause signature verification
        # errors.
        proxy_pass http://localhost:5000;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
}
```
Save and restart nginx. For more on reverse proxy setup see [here](https://matrix-org.github.io/synapse/latest/reverse_proxy.html) for example. (Note: make sure this location block comes before any wildcards blocks which might be matched, and that your server is running on port 5000 or adjust accordingly). 
1. Clone the [Sygnal repo]( https://github.com/matrix-org/sygnal).
2. Create a python virtual environment: `virtualenv -p python3 .venv` and activate it: `source .venv/bin/activate` (you can change `.venv` to whatever directory you like). Note: Sygnal requires Python 3.7+.
3. Run `python setup.py install`; in addition install `service-identity` with `pip install service-identity` (as of writing the library does not come with the setup requirements).
4. Copy the [sample config file](https://github.com/matrix-org/sygnal/blob/main/sygnal.yaml.sample) to `sygnal.yaml` and configure:
	1. Under [`apps`](https://github.com/matrix-org/sygnal/blob/main/sygnal.yaml.sample#L163) change `com.example.myapp.ios` to your app id (Note: this is the same as you use to configure the app in Xcode and on the homeserver).
	2. Under `[your app ID]` uncomment `type: apns`.
	3. Under `certfile` add the path to your APNs certificate file as generated above (Note: this path is relative to the Sygnal root directory).
5. Start by running `python -m sygnal.sygnal` (Note: if you see a warning that the `service-identity` package has not been installed install it as above). 

### Troubleshooting

Troubleshooting notification servers can be tricky but there are a few general steps you can take if things aren't going well.

1. Make sure the homeserver can communicate/acccess the notification server. Simply try something like `curl [Sygnal URL]` from wherever you are running the homeserver. You should see the request come into Sygnal and a 405 on the homeserver side. If you see a 404 there is a good chance of issues with your nginx config, firewalls etc.
2. Make sure you are using the same app Id for your element-ios build, homeserver and Sygnal.
3. Check to see if the push notification are coming through the Sygnal server. You can look directly at the stdout or at the tail of the sygnal.log file. If you see things like `POST: WARNING 'unknown app id"` go to step 2 right above.
4. Make sure that pushers are being registered on the homeserver. Connect to your homeserver `synapse` DB (sqlite, but if you are planning to run this in prod do use postgres), run `select * from pushers`. You should see all the corresponding pushers, one for every active client. Make sure that under the `data` column in the `url` payload key you see the url for the Sygnal server you are running. If you see something like `https://matrix.org/_matrix/push/v1/notify` then it's likely you are not running the latest build config of element-ios. (NOTE: you can always run `delete * from pushers`, they should re-register automatically as needed).
5. Finally, make sure you have allowed notification for your app on the physical device itself. 
