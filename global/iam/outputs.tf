# encrypted outputs can be decrypted using `pbpaste | base64 --decode | gpg -d`
output "passwords" {
  value = zipmap(keys(aws_iam_user_login_profile.this), values(aws_iam_user_login_profile.this).*.encrypted_password)
}

output "access_key_ids" {
  value = zipmap(keys(aws_iam_access_key.this), values(aws_iam_access_key.this).*.id)
}

output "access_key_secrets" {
  value = zipmap(keys(aws_iam_access_key.this), values(aws_iam_access_key.this).*.encrypted_secret)
}