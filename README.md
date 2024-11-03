# Argo CD Extension Installer

![](https://i.imgur.com/waxVImv.png)
### [View all Roadmaps](https://github.com/nholuongut/all-roadmaps) &nbsp;&middot;&nbsp; [Best Practices](https://github.com/nholuongut/all-roadmaps/blob/main/public/best-practices/) &nbsp;&middot;&nbsp; [Questions](https://www.linkedin.com/in/nholuong/)
<br/>

This repo provides a docker image that can be used as an init
container to install Argo CD extensions.

# How to use this image

This image should be added in the Argo CD API server as an init
container. Once the API server starts the init container will download
and install the configured UI extension. All configuration is provided
as environment variables as part of the init container. Find below the
list of all environment variables that can be configured:

| Env Var                   | Required? | Default   | Description                                                                                                                                                                                                         |
|---------------------------|----------|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| EXTENSION_NAME            | Yes      | ""        | Extension Name                                                                                                                                                                                                      |
| EXTENSION_ENABLED         | No       | true      | If set to false will skip the installation. Noop                                                                                                                                                                    |
| EXTENSION_URL             | Yes      | ""        | Must be set to a valid URL where the UI extension can be downloaded from. <br>Argo CD API server needs to have network access to this URL.                                                                          |
| EXTENSION_VERSION         | Yes      | ""        | The version of the extension to be installed.                                                                                                                                                                       |
| EXTENSION_CHECKSUM_URL    | No       | ""        | Can be set to the file containing the checksum to validate the downloaded<br>extension. Will skip the checksum validation if not provided.<br>Argo CD API server needs to have network access to this URL.          |
| MAX_DOWNLOAD_SEC          | No       | 30        | Total time in seconds allowed to download the extension.                                                                                                                                                            |
| EXTENSION_JS_VARS      | No       | ""        | Export the variables to `extension-$EXTENSION_JS_VARS` in js file within the extension folder. These variables will be exported as env variables with key `${EXTENSION_NAME}_VARS`. <br/>The format should be `{key1=value1, key2=value2}`. |


# Examples

## Simple

The simplest way to use this installer is configuring a patch in Argo
CD API server adding an additional initContainer for each extension to
be installed. The example below shows how to configure a hypothetical
extension just providing the required fields.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server
spec:
  template:
    spec:
      initContainers:
        - name: extension-
          image: quay.io/argoprojlabs/argocd-extension-installer:v0.0.5@sha256:27e72f047298188e2de1a73a1901013c274c4760c92f82e6e46cd5fbd0957c6b
          env:
          - name: EXTENSION_URL
            value: https://github.com/some-org/somerepo/releases/download/v0.0.1/extension.tar
          volumeMounts:
            - name: extensions
              mountPath: /tmp/extensions/
          securityContext:
            runAsUser: 1000
            allowPrivilegeEscalation: false
      containers:
        - name: argocd-server
          volumeMounts:
            - name: extensions
              mountPath: /tmp/extensions/
```

> [!NOTE]
> It is a good practice to appended the image digest after the tag to ensure a deterministic and safe image pulling.
> The tag digest can be obtained in quay by clicking in the "fetch tag" icon and select "Docker Pull (by digest)":
> https://github.com/nholuongut/argocd-extension-installer

## Using ConfigMap

The example below demonstrates how to define all extension
configuration in a ConfigMap and use it to configure and update Argo
CD extensions.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: extension-cm
data:
  extension.url: 'http://example.com/extension.tar.gz'
  extension.version: 'v0.3.1'
  # optional fields
  extension.name: 'example'
  extension.enabled: 'true'
  extension.checksum_url: 'http://example.com/extension_checksums.txt'
  extension.max_download_sec: '30'
  extension.js_vars : |
    {
      "key1": "value1",
      "key2": "value2"
    }
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server
spec:
  template:
    spec:
      initContainers:
        - name: extension
          image: quay.io/argoprojlabs/argocd-extension-installer:v0.0.5@sha256:27e72f047298188e2de1a73a1901013c274c4760c92f82e6e46cd5fbd0957c6b
          env:
          - name: EXTENSION_NAME
            valueFrom:
              configMapKeyRef:
                key: extension.name
                name: extension-cm
          - name: EXTENSION_URL
            valueFrom:
             configMapKeyRef:
              key: extension.url
              name: extension-cm
          - name: EXTENSION_VERSION
            valueFrom:
             configMapKeyRef:
              key: extension.version
              name: extension-cm
          - name: EXTENSION_CHECKSUM_URL
            valueFrom:
              configMapKeyRef:
                key: extension.checksum_url
                name: extension-cm
            ## Optional fields
          - name: $EXTENSION_JS_VARS
            valueFrom:
             configMapKeyRef:
              key: extension.js_vars
              name: extension-cm
          volumeMounts:
            - name: extensions
              mountPath: /tmp/extensions/
          securityContext:
            runAsUser: 1000
            allowPrivilegeEscalation: false
      containers:
        - name: argocd-server
          volumeMounts:
            - name: extensions
              mountPath: /tmp/extensions/
```

## Configuring extension vars

Some UI extensions might require some configuration to be provided.
This installer enables this requirement by automatically creating the
necessary javascript file to expose the properties defined in the
`EXTENSION_JS_VARS` variable.

The example below shows how this can be achieved using the ConfigMap
approach:

Add the below configuration in the `extension-cm`:

```yaml
#name should match with the extension name e.g 'Metrics', 'Rollout', 'Ephemeral-Access'
extension.name: 'example'
extension.js_vars : |
     {
       "key1": "value1",
       "key2": "value2"
     }
```

Provide the configuration in argocd-server deployment as below:
```yaml
 ## Optional fields
  - name: $EXTENSION_JS_VARS
    valueFrom:
     configMapKeyRef:
      key: extension.js_vars
      name: extension-cm

```

The installer will create a file as follows:
```js
((window) => {
    const vars = {
        "key1": "value1",  "key2": "value2"
    };
    window.EXAMPLE_VARS = vars;
})(window);
```

Use the exported variables in the extension js file as below:
```js
console.log(window.EXAMPLE_VARS.key1);
console.log(window.EXAMPLE_VARS.key2);
```

Debug:

To test the exported env variables, open the developer console in the browser and type `window` to see the exported variables. The output should be similar to the below:

![image](./image/exported_envirnoment_variables.png)


# 🚀 I'm are always open to your feedback.  Please contact as bellow information:
### [Contact ]
* [Name: Nho Luong]
* [Skype](luongutnho_skype)
* [Github](https://github.com/nholuongut/)
* [Linkedin](https://www.linkedin.com/in/nholuong/)
* [Email Address](luongutnho@hotmail.com)
* [PayPal.me](https://www.paypal.com/paypalme/nholuongut)

![](https://i.imgur.com/waxVImv.png)
![](Donate.png)
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/nholuong)

# License
* Nho Luong (c). All Rights Reserved.🌟
