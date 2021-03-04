# local_envs
ローカル開発環境構築用

## Vagrant
Windows環境にVirtualBoxとVagrantをインストールして使用

```PowerShell
$ vagrant --version
Vagrant 2.2.14
```

CentOS8を使用: https://app.vagrantup.com/centos/boxes/8

### 起動
基本的にはそれぞれのディレクトリの下で`vagrant up`でVM起動(`up`すればboxは自動で`add`される)

```PowerShell
$ vagrant up
```

VMへの接続はディレクトリ内で`vagrant ssh`

### 設定変更
割り当てるIPアドレス当、設定を変更したい場合は各ディレクトリの`Vagrantfile`で指定
このファイル内でディレクトリ内のスクリプトを呼び出してプロビジョニングするように設定している

設定変更の後プロビジョニングからやり直すなら `vagrant reload --provision`

### その他コマンド
Vagrantコマンド: https://qiita.com/oreo3@github/items/4054a4120ccc249676d9

## メモ
最初ifconfig使えなかった: https://qiita.com/s_makinaga/items/ce45f3e20b8edafab9dd

### App

### PostgreSQL
参考になりそうな記事: https://qiita.com/KZ-taran/items/56c1d39dbbdd26df6faf

### SQLServer

## 他関係ないメモ
### EC2にセッションマネージャで接続
ブラウザではなくAWS CLI経由で接続する。(`ssh`, `scp`コマンド使う)
https://qiita.com/hayao_k/items/78b5bfe030ad8a053e93

1. AWS CLIインストール
2. IAMアクセスキー発行・登録
3. Session Manager Pluginインストール
4. SSH Configファイル作成
5. SSHできる(鍵はインスタンスに登録)