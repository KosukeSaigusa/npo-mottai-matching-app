import * as admin from 'firebase-admin'
import { FieldValue } from 'firebase-admin/firestore'

export class ReadWorker {
    constructor({
        workerId,
        path,
        displayName,
        imageUrl,
        isHost,
        createdAt,
        updatedAt
    }: {
        workerId: string
        path: string
        displayName: string
        imageUrl: string
        isHost: boolean
        createdAt?: Date
        updatedAt?: Date
    }) {
        this.workerId = workerId
        this.path = path
        this.displayName = displayName
        this.imageUrl = imageUrl
        this.isHost = isHost
        this.createdAt = createdAt
        this.updatedAt = updatedAt
    }

    readonly workerId: string

    readonly path: string

    readonly displayName: string

    readonly imageUrl: string

    readonly isHost: boolean

    readonly createdAt?: Date

    readonly updatedAt?: Date

    private static fromJson(json: Record<string, unknown>): ReadWorker {
        return new ReadWorker({
            workerId: json[`workerId`] as string,
            path: json[`path`] as string,
            displayName: (json[`displayName`] as string | undefined) ?? ``,
            imageUrl: (json[`imageUrl`] as string | undefined) ?? ``,
            isHost: (json[`isHost`] as boolean | undefined) ?? false,
            createdAt: (
                json[`createdAt`] as FirebaseFirestore.Timestamp | undefined
            )?.toDate(),
            updatedAt: (
                json[`updatedAt`] as FirebaseFirestore.Timestamp | undefined
            )?.toDate()
        })
    }

    static fromDocumentSnapshot(
        ds: FirebaseFirestore.DocumentSnapshot
    ): ReadWorker {
        const data = ds.data()!
        const cleanedData: Record<string, unknown> = {}
        for (const [key, value] of Object.entries(data)) {
            cleanedData[key] = value === null ? undefined : value
        }
        return ReadWorker.fromJson({
            ...cleanedData,
            workerId: ds.id,
            path: ds.ref.path
        })
    }
}

export class CreateWorker {
    constructor({
        displayName,
        imageUrl,
        isHost
    }: {
        displayName: string
        imageUrl: string
        isHost: boolean
    }) {
        this.displayName = displayName
        this.imageUrl = imageUrl
        this.isHost = isHost
    }

    readonly displayName: string

    readonly imageUrl: string

    readonly isHost: boolean

    readonly createdAt?: Date

    toJson(): Record<string, unknown> {
        return {
            displayName: this.displayName,
            imageUrl: this.imageUrl,
            isHost: this.isHost,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp()
        }
    }
}

export class UpdateWorker {
    constructor({
        displayName,
        imageUrl,
        isHost,
        createdAt
    }: {
        displayName?: string
        imageUrl?: string
        isHost?: boolean
        createdAt?: Date
    }) {
        this.displayName = displayName
        this.imageUrl = imageUrl
        this.isHost = isHost
        this.createdAt = createdAt
    }

    readonly displayName?: string

    readonly imageUrl?: string

    readonly isHost?: boolean

    readonly createdAt?: Date

    toJson(): Record<string, unknown> {
        const json: Record<string, unknown> = {}
        if (this.displayName != undefined) {
            json[`displayName`] = this.displayName
        }
        if (this.imageUrl != undefined) {
            json[`imageUrl`] = this.imageUrl
        }
        if (this.isHost != undefined) {
            json[`isHost`] = this.isHost
        }
        if (this.createdAt != undefined) {
            json[`createdAt`] = FirebaseFirestore.Timestamp.fromDate(
                this.createdAt
            )
        }
        json[`updatedAt`] = FieldValue.serverTimestamp()
        return json
    }
}

const db = admin.firestore()
db.settings({ ignoreUndefinedProperties: true })

/**
 * A CollectionReference to workers collection to read.
 */
export const readWorkerCollectionReference = db
    .collection(`workers`)
    .withConverter<ReadWorker>({
        fromFirestore: (ds: FirebaseFirestore.DocumentSnapshot): ReadWorker => {
            return ReadWorker.fromDocumentSnapshot(ds)
        },
        toFirestore: (): FirebaseFirestore.DocumentData => {
            throw Error(`toFirestore is not implemented for ReadWorker`)
        }
    })

/**
 * A DocumentReference to worker document to read.
 */
export const readWorkerDocumentReference = ({
    workerId
}: {
    workerId: string
}): FirebaseFirestore.DocumentReference<ReadWorker> =>
    readWorkerCollectionReference.doc(workerId)

/**
 * A CollectionReference to workers collection to create.
 */
export const createWorkerCollectionReference = db
    .collection(`workers`)
    .withConverter<CreateWorker>({
        fromFirestore: (): CreateWorker => {
            throw new Error(`fromFirestore is not implemented for CreateWorker`)
        },
        toFirestore: (obj: CreateWorker): FirebaseFirestore.DocumentData => {
            return obj.toJson()
        }
    })

/**
 * A [DocumentReference] to worker document to create.
 */
export const createWorkerDocumentReference = ({
    workerId
}: {
    workerId: string
}): FirebaseFirestore.DocumentReference<CreateWorker> =>
    createWorkerCollectionReference.doc(workerId)

/**
 * A CollectionReference to workers collection to update.
 */
export const updateWorkerCollectionReference = db
    .collection(`workers`)
    .withConverter<UpdateWorker>({
        fromFirestore: (): CreateWorker => {
            throw new Error(`fromFirestore is not implemented for CreateWorker`)
        },
        toFirestore: (obj: UpdateWorker): FirebaseFirestore.DocumentData => {
            return obj.toJson()
        }
    })

/**
 * A DocumentReference to worker document to update.
 */
export const updateWorkerDocumentReference = ({
    workerId
}: {
    workerId: string
}): FirebaseFirestore.DocumentReference<UpdateWorker> =>
    updateWorkerCollectionReference.doc(workerId)

/**
 * A CollectionReference to workers collection to delete.
 */
export const deleteWorkerCollectionReference = db.collection(`workers`)

/**
 * A DocumentReference to worker document to delete.
 */
export const deleteWorkerDocumentReference = ({
    workerId
}: {
    workerId: string
}): FirebaseFirestore.DocumentReference =>
    deleteWorkerCollectionReference.doc(workerId)
