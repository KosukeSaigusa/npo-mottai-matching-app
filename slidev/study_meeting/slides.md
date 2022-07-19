---
theme: default
background: https://source.unsplash.com/collection/94734566/1920x1080
class: 'text-center'
highlighter: shiki
info: |
  ## Slidev Starter Template
  Presentation slides for developers.

  Learn more at [Sli.dev](https://sli.dev)
fonts:
  sans: 'Roboto'
  serif: 'Roboto'
  mono: 'Fira Code'
---

# Firebase Functions 入門

2022-06-20 (水) Kosuke Saigusa （Flutter 大学 #共同勉強会）

<div class="abs-br m-6 flex gap-2">
  <a href="https://github.com/KosukeSaigusa/mottai-flutter-app" target="_blank" alt="GitHub"
    class="text-xl icon-btn opacity-50 !border-none !hover:text-white">
    <carbon-logo-github />
  </a>
</div>

---

## 概要

Flutter/Dart と比べると習熟度が低く恐縮ですが、Cloud (Firebase) Functions に関する話をしてみます。

下記のような話題に触れて今までよりも少しでも TypeScript に関する知識が深まったり、Cloud (Firebase) Functions を楽しく快適に書けるようになったりする方が増えたら良いなと思っています。

- Cloud (Firebase) Functions って何？いつ使う？なぜ必要？
- tsconfig.json について
- eslint, prettier について
- package.json, package-lock.json について
- types ディレクトリと .d.ts ファイルについて
- Firebase Functions の概要
- withConverter について
- Firebase Functions の実装例、リポジトリ構成
- Callable Functions について（概要）
- Callable Functions について（実装例）
- Firebase Local Emulator によるデバッグについて

---

## その前に

- [私の GitHub](https://github.com/KosukeSaigusa) のフォロー
- [今回使用するリポジトリへのスター](https://github.com/KosukeSaigusa/mottai-flutter-app)

をお願いしたいです！🙌

---

## Cloud (Firebase) Functions って何？

<https://cloud.google.com/functions/docs/concepts/overview>

> Google Cloud Functions は、クラウド サービスの構築と接続に使用するサーバーレスのランタイム環境です。Cloud Functions を使用すると、クラウドのインフラストラクチャやサービスで生じたイベントに関連する、シンプルで一義的な関数を作成できます。対象のイベントが発生すると、Cloud Functions がトリガーされ、コードがフルマネージドの環境で実行されます。インフラストラクチャをプロビジョニングする必要はなく、サーバーの管理に悩まされることもありません。

要は「サーバレスな関数単位のサーバサイドアプリケーションの実行環境」くらいに捉えると良いと思います。

Firebase との連携も容易で、たとえば Firestore のドキュメントの作成・変更・削除などをトリガーにした関数などは実装が容易で強力です。

---

## Cloud (Firebase) Functions いつ使う？なぜ必要？

バックエンドを Firebase で代替するサービスのサーバサイドアプリケートションとして使用します（Firebase を多様せずとも「サーバレスな関数単位のサーバサイドアプリケーションの実行環境」として使用を検討するケースも多くあります）。

たとえば Firestore を主な DB として使用するアプリケーションでは Cloud (Firebase) Functions は必須です。

- Firestore はクエリが貧弱で Write-heavy な設計になるので、クライアントが単純な読み込みで済むような実装をするために必須なイベントトリガー関数
- Security Rules で制限されたクライアント SDK とは異なる Admin SDK を用いた処理の実行
- プッシュ通知や決済プロバイダ、認証プロバイダなどの外部 API との連携に必要なサーバサイドアプリケーションや HTTP 関数 (Callable Functions) の実装
- Cloud Pub/Sub, Cloud Scheduler を用いた Schedule Functions による定期実行タスクのスケジューリング・実行

その他にも、Firebase Auth や Firebase Storage のイベントなどをトリガーにした関数も簡単に定義することができます。

---

## Cloud (Firebase) Functions の始め方

```sh
# Firebase CLI（firebase コマンド）の導入
npm install -g firebase-tools

# firebase プロジェクトのイニシャライズ
firebase init
```

ちなみに個人的には npm や node の環境構築には最近は [VOLTA](https://volta.sh/) をおすすめしています。

また Dart を普段から取り扱うであろう皆さんには、JavaScript ではなく TypeScript での開発を推奨し、その前提で話を進めます。

詳細は ... を参考にしてください。

---

## tsconfig.json について

`tsconfig.json` とは、すべての TypeScript プロジェクトのルートに必ず設置され、

- どのファイルをコンパイル（トランスパイル）対象とすべきか
- コンパイル（トランスパイル）結果をどのディレクトリに格納すべきか
- どのバージョンの JavaScript を出力するか
- ベースディレクトリの設定
- モジュール内のパスマッピング
- ...

などを TypeScript プロジェクトが定義するためのファイルです。

[サンプルプロジェクトの tsconfig.json](https://github.com/KosukeSaigusa/mottai-flutter-app-firebase/blob/main/functions/tsconfig.json)

---

## tsconfig.json の例

```json
{
    "compilerOptions": {
        "module": "CommonJS",
        "moduleResolution": "node",
        "resolveJsonModule": true,
        "noImplicitReturns": true,
        "noUnusedLocals": true,
        "outDir": "lib",
        "sourceMap": true,
        "strict": true,
        "target": "es2020",
        "baseUrl": "./",
        "paths": {
            "~/*": ["./*"]
        },
        "types": ["@types/node"]
    },
    "compileOnSave": true,
    "exclude": ["node_modules", "lib"]
}

```

---

## eslint について

ESLint とは JavaScript (EcmaScript) のための静的解析ツールです。

js, json, yaml などの形式で静的解析のルールやその他の設定を定義することができます。

VSCode に [eslint の拡張機能](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)をまだ導入していない場合は、インストールして VSCode を再起動しましょう。

[サンプルプロジェクトの .eslintrc.js](https://github.com/KosukeSaigusa/mottai-flutter-app-firebase/blob/main/functions/.eslintrc.js)

---

## prettier について

prettier は eslint としばしば併用されるコード整形ツールです。

デフォルト値以外の設定は `.prettierrc` に設定することができます。

VSCode に [prettier の拡張機能](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)をまだ導入していない場合は、インストールして VSCode を再起動しましょう。

[サンプルプロジェクトの .eslintrc.js](https://github.com/KosukeSaigusa/mottai-flutter-app-firebase/blob/main/functions/.prettierrc)

---

## eslint の設定例 1

`.eslintrc.js` の設定例です。prettier のプラグインと合わせて良い感じに使えます。

```js
module.exports = {
    root: true,
    env: {
        es6: true,
        node: true
    },
    extends: [
        `eslint:recommended`,
        `plugin:import/typescript`,
        `plugin:@typescript-eslint/eslint-recommended`,
        `plugin:@typescript-eslint/recommended`,
        `plugin:import/errors`,
        `plugin:import/warnings`,
        `prettier`
    ],
    // 省略...
}
```

---

## eslint の設定例 2

```js
module.exports = {
    // ...省略
    parser: `@typescript-eslint/parser`,
    ignorePatterns: [`/lib/**/*`],
    plugins: [`node`, `@typescript-eslint`, `import`],
    rules: {
        quotes: [`error`, `backtick`]
    },
    settings: {
        'import/resolver': {
            typescript: { project: `./` }
        }
    }
}

```

---

## VSCode の eslint, prettier の設定の例

VSCode の場合は、settings.json に下記のような設定をすると prettier によるコード整形と eslint の静的解析に従ったコード修正が自動で働きます。

```json
{
  // JS, TS 関係
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnType": true,
    "editor.codeActionsOnSave": {
      "source.fixAll": true
    }
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll": true
    }
  },
}
```

---

## その他の VSCode 設定の例

今回のプロジェクトでは、TypeScript プロジェクトが VSCode のワークスペースのルートになく、VSCode が （tsconfig でパスマッピングした）import 文を正しく認識できずに、結構ハマりました。

必要に応じてワークスペースの `settings.json` に下記のように `functions` ディレクトリまでのパスを定義してください。

```json
{
  "eslint.workingDirectories": ["path/to/functions"],
}
```

今回のプロジェクトで具体的には、

```json
{
  "eslint.workingDirectories": ["./mottai-flutter-app-firebase/functions"],
}
```

が必要でした。

---

## package.json, package-lock.json について

`package.json` とは JavaScript や Node.js プロジェクト（パッケージ）のルートに設置し、プロジェクトに関する様々なメタデータや設定を記述するファイルです。

たとえば、プロジェクトが依存する外部パッケージを記述したり、`npm run something` で実行したいスクリプトを定義したりすることができます。

`package-lock.json` とは、`package.json` を元に解決したすべての依存性が記述され、固定化して使用するためのファイルです。

Dart のプロジェクトにとっての `pubspec.yaml`, `pubspec-lock.yaml` と同じものだと捉えて問題ありません。

---

## package.json の例 1

[サンプルプロジェクトの package.json](https://github.com/KosukeSaigusa/mottai-flutter-app-firebase/blob/main/functions/package.json)

```json
{
    "name": "functions",
    "scripts": {
        "lint": "eslint --ext .js,.ts .",
        "lint-fix": "eslint --fix './{lib,src,test}/**/*.{ts,tsx}' && prettier --write './{lib,src,test}/**/*.{ts,tsx}'",
        "build": "tsc && tsc-alias",
        "watch": "concurrently \"tsc -w\" \"tsc-alias -w\"",
        "serve": "npm run build && firebase emulators:start --only functions",
        "shell": "npm run build && firebase functions:shell",
        "start": "npm run shell",
        "deploy": "firebase deploy --only functions",
        "logs": "firebase functions:log"
    },
    "engines": {
        "node": "16"
    },
    "main": "lib/src/index.js",
}
```

---

## package.json の例 2

dependencies には `firebase-admin`, `firebase-functions` などの必須のパッケージや、`@google-cloud/firestore` のような Firestore 関係の型定義パッケージなどが含まれます。

```json
{
    // ...省略
    "dependencies": {
        "@google-cloud/firestore": "^5.0.2",
        "@types/uuid": "^8.3.4",
        "axios": "0.27.2",
        "firebase-admin": "^11.0.0",
        "firebase-functions": "^3.22.0",
        "uuid": "^8.3.2"
    },
    // ...省略
}
```

---

## package.json の例 3

eslint, prettier 関係の設定が含まれています。

また、import とモジュールのパスマッピング関係の設定（`eslint-import-resolver-typescript`, `tsc-alias`, `concurrently` など）が含まれます。これをある程度理解して快適に動作するようにするには結構骨が折れました...

```json
{
    // ...省略
    "devDependencies": {
        "@typescript-eslint/eslint-plugin": "^5.30.6",
        "@typescript-eslint/parser": "^5.30.6",
        "concurrently": "^7.3.0",
        "eslint": "^8.20.0",
        "eslint-config-google": "^0.14.0",
        "eslint-config-prettier": "^8.5.0",
        "eslint-import-resolver-typescript": "^3.2.7",
        "eslint-plugin-import": "^2.26.0",
        "eslint-plugin-node": "^11.1.0",
        "firebase-functions-test": "^2.2.0",
        "prettier": "^2.7.1",
        "tsc-alias": "^1.7.0",
        "typescript": "^4.7.4"
    },
}
```

---

## types ディレクトリと .d.ts ファイルについて

`.d.ts` のファイルを型定義ファイルといいます。

TypeScript を JavaScript にコンパイル（トランスパイル）すると、本来型情報は失われますが、`.d.ts` ファイルを定義することで、エディタや IDE のコード補完やコードチェックの恩恵を受けることができます。

ambient (global) module declaration となるので、import や export 文は不要になります。

型定義ファイルは `src/@types` や `src/types` ディレクトリに配置するのが慣習のようです。

---

## Firebase Functions の概要 1

Firebase Functions (Cloud Functions for Firebase) で最もよく使うもののひとつは、Firestore のイベントの作成・更新・削除などをトリガーにした関数 (Cloud Firestore triggers) です。

`firebase-functions` パッケージは `as functions` としてインポートするのが通例で、下記のような記述を行うことで `accounts` コレクションの任意のドキュメント (`accountId`) が作成されたときに発火する関数を定義することができます。

```ts
import * as functions from 'firebase-functions'

export const onCreateAccount = functions
    .region(`asia-northeast1`)
    .firestore.document(`/accounts/{accountId}`)
    .onCreate(async (snapshot) => {
      // ...
    })
```

---

## Firebase Functions の概要 2

下記の `onCreate` は第 1 引数に `QueryDocumentSnapshot (snapshot)` を、第 2 引数に `EventContext (context)` をとることができます。

```ts
export const onCreateAccount = functions
    .region(`asia-northeast1`)
    .firestore.document(`/accounts/{accountId}`)
    .onCreate(async (snapshot, context) => {
      // ...
    })
```

`snapshot` には、この関数の onCreate の引き金となったドキュメントの `QueryDocumentSnapshot` が入っています。`snapshot.data()` とすることでドキュメントのデータにアクセスすることができます。

`context` には、このトリガーされたイベントに関する認証情報やその他のメタデータのようなものが入っています。たとえば `context.params.accountId` とすると、onCreate の引き金となったドキュメントのドキュメント ID を得ることができます。

---

## withConverter について 1

FlutterFire でもお馴染みですが `withConverter` を用いると、Firestore の `CollectionReference<T>`, `DocumentReference<T>`, `DocumentSnapshot<T>` `DocumentData<T>` に型をつけることができます。

JS (TS) の Firestore でも同様です。

まず、型定義ファイルにドキュメントの内容に合う型を定義してください。TypeScript の（いわゆる）型定義（みたいなもの）には複数の方法がありますが、ここでは `interface` を用いることにします。

```ts
/** Firestore の account コレクションのドキュメントデータの型。 */
interface AppAccount {
  accountId: string
  createdAt?: FirebaseFirestore.Timestamp
  updatedAt?: FirebaseFirestore.Timestamp
  displayName: string
  imageURL: string
  providers: string[]
  fcmTokens: string[]
}
```

---

## withConverter について 2

`withConverter` の引数にわたす `FirestoreDataConverter<T>` を定義します。

```ts
import { FieldValue, FirestoreDataConverter } from "@google-cloud/firestore"

export const accountConverter: FirestoreDataConverter<AppAccount> = {
    fromFirestore(qds: FirebaseFirestore.QueryDocumentSnapshot): AppAccount {
        const data = qds.data()
        return {
            accountId: qds.id,
            createdAt: data.createdAt,
            updatedAt: data.updatedAt,
            displayName: data.displayName ?? ``,
            imageURL: data.imageURL ?? ``,
            providers: data.providers ?? [],
            fcmTokens: data.fcmTokens ?? []
        }
    },
    // ... toFirestore 省略
}
```

---

## withConverter について 3

`withConverter` の引数にわたす `FirestoreDataConverter<T>` を定義します。

```ts
import { FieldValue, FirestoreDataConverter } from "@google-cloud/firestore"

export const accountConverter: FirestoreDataConverter<AppAccount> = {
    // ... fromFirestore 省略
    toFirestore(account: AppAccount): FirebaseFirestore.DocumentData {
        return {
            accountId: account.accountId,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            displayName: account.displayName ?? ``,
            imageURL: account.imageURL ?? ``,
            providers: account.providers ?? [],
            fcmTokens: account.fcmTokens ?? []
        }
    }
}
```

---

## withConverter について 4

たとえば `withConverter` を用いて account コレクションの型付き `CollectionReference<AppAccount>` を返す変数や、account ドキュメントの ID を渡すと型付き `DocumentReference<AppAccount>` を返すメソッドを作っておいたりすると便利です。

```ts
import * as admin from 'firebase-admin'
import { CollectionReference, DocumentReference, Query } from '@google-cloud/firestore'
import { accountConverter } from '../converters/accountConverter'

/** accounts コレクションの参照 */
const accountsRef: CollectionReference<AppAccount> = admin.firestore()
    .collection(`accounts`)
    .withConverter<AppAccount>(accountConverter)

/** 指定した account ドキュメントの参照 */
const accountRef = (
    { accountId }: { accountId: string }
): DocumentReference<AppAccount> => {
    return accountsRef.doc(accountId).withConverter<AppAccount>(accountConverter)
}
```

---

## withConverter について 5

あとは `onCreate` の第 1 引数から得られる `DocumentSnapshot (snapshot)` を `accountConverter.fromFirestore` に渡すとそれだけで変数 `account` には `AppAccount` の型が付いています。

```ts {5}
export const onCreateAccount = functions
    .region(`asia-northeast1`)
    .firestore.document(`/accounts/{accountId}`)
    .onCreate(async (snapshot) => {
        const account = accountConverter.fromFirestore(snapshot)
    })
```

また、update イベントのトリガー関数なら、イベントによる更新前後の `DocumentSnapshot (snapshot)` がそれぞれ `snapshot.before`, `snapshot.after` で取れるので、同様にかんたんに型を付けられます。

```ts {5,6}
export const onUpdateAccount = functions
    .region(`asia-northeast1`)
    .firestore.document(`/accounts/{accountId}`)
    .onUpdate(async (snapshot) => {
        const before = accountConverter.fromFirestore(snapshot.before)
        const after = accountConverter.fromFirestore(snapshot.after)
        // ...
    })
```

---

## Firebase Functions の実装例

`accounts` コレクションの任意のドキュメントが新規作成されたときに、`publicUsers` コレクションに対応するドキュメントを作成する関数。

```ts
export const onCreateAccount = functions
    .region(`asia-northeast1`)
    .firestore.document(`/accounts/{accountId}`)
    .onCreate(async (snapshot) => {
        const account = accountConverter.fromFirestore(snapshot)
        const publicUser = new PublicUser({
            userId: account.accountId,
            displayName: account.displayName,
            imageURL: account.imageURL
        })
        try {
            await publicUserRef({ publicUserId: account.accountId }).set(publicUser)
        } catch (e) {
            functions.logger.error(`account ドキュメントの作成に伴う publicUser の作成に失敗しました: ${e}`)
        }
    })
```

また、`accounts` ドキュメントから Firebase Functions 経由で `publicUsers` ドキュメントを作る理由に思いを馳せると、Firestore のデータモデリング、Security Rules や読み書きの分離について考えるきっかけになります。

---

## Firebase Functions のリポジトリ構成の例

プロダクションレベルで Cloud (Firebase) Functions を中心とした大きなアプリケーションを運用・開発したことはない前提ですが、今日見せた例に沿った規模感小さめのものであれば次のような構成でそれなりにすっきり書けそうです。

```txt
- index.ts
- batch
- callable-functions
- converters
- firebase-functions
  - account
    - onCreateAccount.ts
    - onUpdateAccount.ts
- firestore-refs
- models
- repositories
- types
- utils
```

共通処理が膨れてくれば、`logic` みたいなディレクトリを作って、その下に関心事の名前でディレクトリを作成していくのも良いかもしれません。

時間があれば、`models` と types 以下の型定義ファイルの `interface` について言及します。

---

## Callable Functions の概要

今まで紹介した Firestore のイベントトリガー関数は強力ですが、Firestore のイベントとは関係なく、クライアントが HTTP リクエストをすることで外部の API と連携した機能を提供し、レスポンスを返したいこともよくあります。

<https://firebase.google.com/docs/functions/callable>

> Cloud Functions for Firebase のクライアント SDK を使用すると、Firebase アプリから関数を直接呼び出すことができます。この方法でアプリから関数を呼び出すには、Cloud Functions において HTTPS 呼び出し可能関数を記述してデプロイし、アプリから関数を呼び出すためのクライアント ロジックを追加します。

要は「Cloud (Firebase) Functions のひとつとして HTTP のエンドポイントを定義できる機能」くらいに捉えると良いと思います。

ただし、HTTPS の Callable Functions と [HTTP Functions](https://cloud.google.com/functions/docs/writing/http) は似ているものの、

> - Callable Functions では、Firebase Authentication トークン、FCM トークン、App Check トークンが利用可能な場合、自動的にリクエストに追加されます。
> - functions.https.onCall トリガーは、リクエストボディを自動的にデシリアライズし、認証トークンを検証します。

とあるように、Firebase に特化した認証周りやその他の機能が利用できます。

---

## Callable Functions の実装例

次のようにして Callable Functions は実装することができます。

```ts
import * as functions from 'firebase-functions'

export const yourCallableFunctionName = functions.region(`asia-northeast1`).https.onCall(async (data) => {
    // ...省略
    const foo = 'foo'
    const bar = 'bar'
    try {
        return { foo, bar }
    } catch (e) {
        throw new functions.https.HttpsError(`internal`, `失敗メッセージ`)
    }
})
```

[サンプルプロジェクトの Callable Functions](https://github.com/KosukeSaigusa/mottai-flutter-app-firebase/blob/main/functions/src/callable-functions/custom-token/createFirebaseAuthCustomToken.ts)

時間があればサンプルプロジェクトの Firebase Auth と LINE ログインの連携のための Custom Token 認証を行う Callable Functions について言及します。

---

## Firebase Local Emulator によるデバッグ 1

Firebase Local Emulator の導入の詳細の説明は省略しますが、次のように `--inspect-functions` のオプションを付けてエミュレータを起動します。

```sh
firebase emulators:start --inspect-functions
```

ついでに Firestore Emulator のデータの永続化のための読み書きのオプションもつけて

```sh
firebase emulators:start --inspect-functions --import data --export-on-exit
```

で起動することが多いです。

---

## Firebase Local Emulator によるデバッグ 2

さらに、VSCode の `launch.json` には次のような設定を書き加えて起動 (attach) すると、VSCode 上で Cloud Functions のソースコードにブレイクポイントを打って開発を進めることができます。

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Functions (local)",
      "type": "node",
      "request": "attach",
      "restart": true,
      "port": 9229 // firebase emulator のデフォルトのポート番号
    }
  ]
}
```

---

## Cloud Functions のテスト
