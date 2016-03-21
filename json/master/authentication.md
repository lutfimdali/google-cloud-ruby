## With `gcloud-ruby`

With `gcloud-ruby` it's incredibly easy to get authenticated and start using Google's APIs. You can set your credentials on a global basis as well as on a per-API basis.

### Project and Credential Lookup

Gcloud aims to make authentication as simple as possible, and provides several mechanisms to configure your system without providing **Project ID** and **Service Account Credentials** directly in code.

**Project ID** is discovered in the following order:

1. Specify project ID in code
2. Discover project ID in environment variables
3. Discover GCE project ID

**Credentials** are discovered in the following order:

1. Specify credentials in code
2. Discover credentials path in environment variables
3. Discover credentials JSON in environment variables
4. Discover credentials file in the Cloud SDK's path
5. Discover GCE credentials

### Environment Variables

The **Project ID** and **Credentials JSON** can be placed in environment variables instead of declaring them directly in code. Each service has its own environment variable, allowing for different service accounts to be used for different services. The path to the **Credentials JSON** file can be stored in the environment variable, or the **Credentials JSON** itself can be stored for environments such as Docker containers where writing files is difficult or not encouraged.

Here are the environment variables that Datastore checks for project ID:

1. DATASTORE_PROJECT
2. GCLOUD_PROJECT

Here are the environment variables that Datastore checks for credentials:

1. DATASTORE_KEYFILE - Path to JSON file
2. GCLOUD_KEYFILE - Path to JSON file
3. DATASTORE_KEYFILE_JSON - JSON contents
4. GCLOUD_KEYFILE_JSON - JSON contents



