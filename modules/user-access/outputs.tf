# encrypted outputs can be decrypted using `pbpaste | base64 --decode | gpg -d`
output "passwords" {
  value = zipmap(keys(aws_iam_user_login_profile.this), values(aws_iam_user_login_profile.this).*.encrypted_password)
}