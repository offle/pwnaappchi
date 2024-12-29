import Foundation
import SwiftUI

struct SettingsView: View {
    @State private var pwnIp: String = UserDefaults.standard.string(forKey: "pwnIp") ?? ""
    @State private var linuxUser: String = UserDefaults.standard.string(forKey: "linuxUser") ?? ""
    @State private var linuxPassword: String = UserDefaults.standard.string(forKey: "linuxPassword") ?? ""
    @State private var captureDir: String = UserDefaults.standard.string(forKey: "captureDir") ?? ""
    @State private var maxDownloadCount: String = UserDefaults.standard.string(forKey: "maxDownloadCount") ?? ""
    @State private var bettercapPort: String = UserDefaults.standard.string(forKey: "bettercapPort") ?? ""
    @State private var bettercapUser: String = UserDefaults.standard.string(forKey: "bettercapUser") ?? ""
    @State private var bettercapPassword: String = UserDefaults.standard.string(forKey: "bettercapPassword") ?? ""
    @State private var mapAccuracy: String = UserDefaults.standard.string(forKey: "mapAccuracy") ?? ""
    
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(destination: EditableFieldView(label: "pwnIp", value: $pwnIp)) {
                        SettingsRow(title: "Pwnagotchi IP", value: pwnIp)
                    }
                } header: {
                    Text("IP of your Pwny")
                }
                
                Section {
                    NavigationLink(destination: EditableFieldView(label: "linuxUser", value: $linuxUser)) {
                        SettingsRow(title: "Linux Root User", value: linuxUser)
                    }
                    NavigationLink(destination: EditableFieldView(label: "linuxPassword", value: $linuxPassword, isSecure: true)) {
                        SettingsRow(title: "Linux Root Password", value: linuxPassword, isSecure: true)
                    }
                } header: {
                    Text("Linux User")
                } footer: {
                    Text("root or any user with access to the Capture Directory and /etc/pwnagotchi/config.toml")
                }
                
                
                Section {
                    NavigationLink(destination: EditableFieldView(label: "captureDir", value: $captureDir)) {
                        SettingsRow(title: "Capture Directory", value: captureDir)
                    }
                } header: {
                    Text("Capture Directory")
                } footer: {
                    Text("Directory where the Captures, Net-Pos, GEO and GPS files are stored")
                }
                
                
                Section {
                    NavigationLink(destination: EditableFieldView(label: "maxDownloadCount", value: $maxDownloadCount)) {
                        SettingsRow(title: "Maximum Files Download", value: maxDownloadCount)
                    }
                } header: {
                    Text("Downloads")
                } footer: {
                    Text("Number of files to be downloaded. The newest files are downloaded first. A value of 0 will download all files")
                }
                
                Section {
                    NavigationLink(destination: EditableFieldView(label: "bettercapUser", value: $bettercapUser)) {
                        SettingsRow(title: "Bettercap User", value: bettercapUser)
                    }
                    .listRowSeparator(.hidden)
                    NavigationLink(destination: EditableFieldView(label: "bettercapPassword", value: $bettercapPassword, isSecure: true)) {
                        SettingsRow(title: "Bettercap Password", value: bettercapPassword, isSecure: true)
                    }
                    .listRowSeparator(.hidden)
                    NavigationLink(destination: EditableFieldView(label: "bettercapPort", value: $bettercapPort)) {
                        SettingsRow(title: "Bettercap Port", value: bettercapPort)
                    }
                } header: {
                    Text("Bettercap API")
                } footer: {
                    Text("Currently not used")
                }
                
                Section {
                    NavigationLink(destination: EditableFieldView(label: "mapAccuracy", value: $mapAccuracy)) {
                        SettingsRow(title: "Map Accuracy", value: mapAccuracy)
                    }
                } header: {
                    Text("Map Accuracy threshold")
                } footer: {
                    Text("Maximum value of accuracy of the geo/gps files in meters for the Map View. Lower is better ;) 0 is infinite")
                    
                }
                
                Section {
                    NavigationLink(destination: LicenseInfoView()) {
                        Text("Licenses & Information")
                            .foregroundColor(.blue)
                    }
                }
                
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsRow: View {
    var title: String
    var value: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(isSecure ? String(repeating: "•", count: value.count) : (value.isEmpty ? "Not Set" : value))
                .foregroundColor(.gray)
        }
    }
}

struct EditableFieldView: View {
    var label: String
    @Binding var value: String
    var isSecure: Bool = false
    
    var body: some View {
        Form {
            if isSecure {
                SecureField(label, text: $value)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(5)
            } else {
                TextField(label, text: $value)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.default)
                    .autocorrectionDisabled(true)
                    .padding(5)
            }
        }
        .navigationTitle(label)
        .navigationBarTitleDisplayMode(.inline)
        //        .onChange(of: value) { newValue in
        //            UserDefaults.standard.set(newValue, forKey: label)
        //        }
        .onChange(of: value) { oldValue, newValue in
            UserDefaults.standard.set(newValue, forKey: label)
        }
        .onAppear {
            // Optional: Set the initial value from UserDefaults if necessary
            value = UserDefaults.standard.string(forKey: label) ?? ""
        }
    }
}


