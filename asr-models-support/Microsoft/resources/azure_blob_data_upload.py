import os, uuid
import argparse

from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient


def upload_blob(blob_service_client: BlobServiceClient, data_file_path: str, blob_name_prefix: str, container_name: str):
    # create a blob client
    blob_name = blob_name_prefix + str(uuid.uuid4())
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
    
    # upload file to blob
    print("\nUploading " + data_file_path + " to Azure Storage as blob:\n\t" + blob_name)
    with open(data_file_path, "rb") as data:
        blob_client.upload_blob(data)


def create_container(blob_service_client: BlobServiceClient, container_name_prefix: str, connect_str: str) -> str:

    # Create a unique name for the container
    container_name = container_name_prefix + str(uuid.uuid4())

    # Create the container
    print("Creating container with name {}".format(container_name))
    container_client = blob_service_client.create_container(container_name)
    return container_name


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--container_name", type=str, help="Name of container to upload blobs to. Will create \
                                                            new container if container name is not provided.")
    parser.add_argument("--container_name_prefix", type=str, help="Name prefix to use when creating new container to store blobs in. \
                                                                   (Only used if container_name is not provided). Must contain \
                                                                    lower case letters only.")
    parser.add_argument("--data_file_paths", type=str, nargs='+', help="Paths to files to upload to blob storage.")
    parser.add_argument("--blob_name_prefixes", type=str, nargs='+', help="Prefixes to use when naming blobs. There \
                                                                           should be one per data file path provided.") 
    args = parser.parse_args()
    if len(args.data_file_paths) != len(args.blob_name_prefixes):
        print("Need one blob name prefix per input data file. Instead got {} blob prefixes \
               and {} data file paths.".format(len(args.blob_name_prefixes), len(args.data_file_paths)))
        exit(1)
    return args


def main():
    # parse args
    args = parse_args()

    try:
        # Retrieve the connection string for use with the application. The storage
        # connection string is stored in an environment variable on the machine
        # running the application called AZURE_STORAGE_CONNECTION_STRING. If the environment variable is
        # created after the application is launched in a console or with Visual Studio,
        # the shell or application needs to be closed and reloaded to take the
        # environment variable into account.
        connect_str = os.getenv('AZURE_STORAGE_CONNECTION_STRING')

        
        # Create the BlobServiceClient object which will be used to create a container client
        blob_service_client = BlobServiceClient.from_connection_string(connect_str)
        
        # create container
        container_name = args.container_name
        if container_name is None:
            container_name = create_container(blob_service_client, args.container_name_prefix, connect_str)

        for file_path, blob_prefix in zip(args.data_file_paths, args.blob_name_prefixes):
            upload_blob(blob_service_client, file_path, blob_prefix, container_name)
    
    except Exception as ex:
        print('Exception:')
        print(ex)


if __name__ == "__main__":
    main()
