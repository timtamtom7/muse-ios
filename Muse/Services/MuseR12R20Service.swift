import Foundation
import Combine

final class MuseR12R20Service: ObservableObject, @unchecked Sendable {
    static let shared = MuseR12R20Service()
    
    @Published var ensembleProjects: [EnsembleProject] = []
    @Published var collaborations: [RealTimeCollaboration] = []
    @Published var soundPacks: [SoundPack] = []
    @Published var midiExports: [MIDIExport] = []
    @Published var currentTier: MuseSubscriptionTier = .free
    @Published var crossPlatformDevices: [CrossPlatformDevice] = []
    @Published var awardSubmissions: [AwardSubmission] = []
    @Published var apiCredentials: MuseAPI?
    
    private let userDefaults = UserDefaults.standard
    
    private init() { loadFromDisk() }
    
    func createEnsembleProject(name: String, ownerID: String) -> EnsembleProject {
        let project = EnsembleProject(name: name, ownerID: ownerID)
        ensembleProjects.append(project)
        saveToDisk()
        return project
    }
    
    func inviteCollaborator(projectID: UUID, userID: String) {
        guard let index = ensembleProjects.firstIndex(where: { $0.id == projectID }) else { return }
        if !ensembleProjects[index].collaboratorIDs.contains(userID) {
            ensembleProjects[index].collaboratorIDs.append(userID)
        }
        saveToDisk()
    }
    
    func createCollaboration(projectID: UUID, participantIDs: [String]) -> RealTimeCollaboration {
        let collab = RealTimeCollaboration(projectID: projectID, participantIDs: participantIDs)
        collaborations.append(collab)
        saveToDisk()
        return collab
    }
    
    func addSoundPack(name: String, creatorName: String, category: SoundPack.Category, isPremium: Bool = false) -> SoundPack {
        let pack = SoundPack(name: name, creatorName: creatorName, category: category, isPremium: isPremium)
        soundPacks.append(pack)
        saveToDisk()
        return pack
    }
    
    func exportMIDI(projectID: UUID, format: MIDIExport.Format) -> MIDIExport {
        let export = MIDIExport(projectID: projectID, format: format)
        midiExports.append(export)
        saveToDisk()
        return export
    }
    
    func subscribe(to tier: MuseSubscriptionTier) async -> Bool {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run { currentTier = tier; saveToDisk() }
        return true
    }
    
    func submitAward(name: String, category: String) -> AwardSubmission {
        let award = AwardSubmission(awardName: name, category: category)
        awardSubmissions.append(award)
        saveToDisk()
        return award
    }
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(ensembleProjects) { userDefaults.set(data, forKey: "muse_ensembles") }
        if let data = try? encoder.encode(collaborations) { userDefaults.set(data, forKey: "muse_collabs") }
        if let data = try? encoder.encode(soundPacks) { userDefaults.set(data, forKey: "muse_soundpacks") }
        if let data = try? encoder.encode(midiExports) { userDefaults.set(data, forKey: "muse_exports") }
        if let data = try? encoder.encode(crossPlatformDevices) { userDefaults.set(data, forKey: "muse_devices") }
        if let data = try? encoder.encode(awardSubmissions) { userDefaults.set(data, forKey: "muse_awards") }
    }
    
    private func loadFromDisk() {
        let decoder = JSONDecoder()
        if let data = userDefaults.data(forKey: "muse_ensembles"),
           let decoded = try? decoder.decode([EnsembleProject].self, from: data) { ensembleProjects = decoded }
        if let data = userDefaults.data(forKey: "muse_collabs"),
           let decoded = try? decoder.decode([RealTimeCollaboration].self, from: data) { collaborations = decoded }
        if let data = userDefaults.data(forKey: "muse_soundpacks"),
           let decoded = try? decoder.decode([SoundPack].self, from: data) { soundPacks = decoded }
        if let data = userDefaults.data(forKey: "muse_exports"),
           let decoded = try? decoder.decode([MIDIExport].self, from: data) { midiExports = decoded }
        if let data = userDefaults.data(forKey: "muse_devices"),
           let decoded = try? decoder.decode([CrossPlatformDevice].self, from: data) { crossPlatformDevices = decoded }
        if let data = userDefaults.data(forKey: "muse_awards"),
           let decoded = try? decoder.decode([AwardSubmission].self, from: data) { awardSubmissions = decoded }
    }
}
