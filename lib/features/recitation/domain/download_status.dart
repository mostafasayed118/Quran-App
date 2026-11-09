/// Download lifecycle shared by the registry, the queue cubit and the UI.
/// The DB stores the enum [name] so the wire format stays human-readable.
enum DownloadStatus { queued, downloading, done, failed }
