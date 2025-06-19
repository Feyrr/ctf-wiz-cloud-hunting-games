findmnt
- Displays mounted file systems in a tree format.
- Commonly used to verify mount points and types.

nohup ncat --ssl -klp 8443 > /tmp/.../keys_out.txt &
- Starts a background SSL-secured listener on port 8443 using ncat.
- Logs anything received into keys_out.txt.
- nohup allows it to keep running after logout.

cat /tmp/.../keys_out.txt
- Reads and displays the contents collected by the ncat listener.

aws sts get-caller-identity
- Retrieves the identity of the IAM user or role currently authenticated.

aws lambda invoke --function-name log-service-status --cli-binary-format raw-in-base64-out --payload {"service": "postgresql", "status": 3}
- Triggers a Lambda function named log-service-status.
- The payload includes the "service": "postgresql" and a "status" code.
- Status 3 could mean failure or down, and 1 might mean running or OK, depending on your logic.

mkdir /home/postgresql-user/overlay-upper /home/postgresql-user/overlay-lower /home/postgresql-user/overlay-work /home/postgresql-user/overlay-mount
- Prepares directories likely for use with OverlayFS, a type of union filesystem.
- Used to layer filesystems (common in container or sandboxing setups).
