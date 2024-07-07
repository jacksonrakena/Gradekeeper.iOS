//
//  ContentView.swift
//  Shared
//
//  Created by Jackson Rakena on 10/08/22.
//

import SwiftUI
import CoreData
import GoogleSignInSwift
import GoogleSignIn

class Network: ObservableObject {
    @Published var user: User? = nil
    func getUser(token: String) {
        let url = URL(string: "https://api.gradekeeper.xyz/api/users/me")!

        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }

            print("Fuck: \(response.statusCode)")
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decoder = JSONDecoder()
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                        decoder.dateDecodingStrategy = .formatted(formatter)
                        let decodedUsers = try decoder.decode(User.self, from: data)
                        self.user = decodedUsers
                        print("Decoded")
                        print("\(self.user?.studyBlocks.count) blocks")
                    } catch let error {
                        print("Error decoding", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
}
struct User: Decodable {
    var studyBlocks: [StudyBlock]
}
struct StudyBlock: Identifiable, Decodable {
    var id: String
    var startDate: Date
    var endDate: Date
    var name: String
    var userId: String
    var courses: [Course]
}
struct Course: Identifiable, Decodable {
    var id: String
    var longName: String
    var courseCodeName: String
    var courseCodeNumber: String
    var color: String
}
struct StudyBlockView: View {
    var sb: StudyBlock
    func randomUIColor() -> UIColor {
            var total: Int = 0
            for u in "Hello".unicodeScalars {
                total += Int(UInt32(u))
            }
            srand48(total * 200)
            let r = CGFloat(drand48())
            srand48(total)
            let g = CGFloat(drand48())
            srand48(total / 200)
            let b = CGFloat(drand48())
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        }
        
        func randomColor() -> Color {
            return Color(self.randomUIColor()).opacity(1)
        }
    var body: some View {
        ForEach(sb.courses) { course in
            NavigationLink(destination: Text("\(course.longName)")) {
                VStack {
                    Text("\(course.courseCodeName) \(course.courseCodeNumber)").foregroundColor(.white)
                    Text("\(course.longName)").foregroundColor(.white).font(.headline)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(/*LinearGradient(
                               gradient: .init(colors: [Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255), Utils.randomColor(seed: period.SubjectDesc)]),
                               startPoint: .init(x: 0, y: 1),
                               endPoint: .init(x: 1, y: 0)
                               ))*/ Color.init(hex: course.color))).padding(.horizontal, 15).padding(.top, 5).shadow(radius: 10)
            }
        }
    }
}
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @EnvironmentObject var network: Network
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            ScrollView {
                GoogleSignInButton {
                    GIDSignIn.sharedInstance.signIn(withPresenting: self.getRootViewController()) { signInResult, error in
                        guard error == nil else {
                            print("Error \(error)")
                            return
                        }
                        guard let result = signInResult else {
                            return
                        }
                        
                        result.user.refreshTokensIfNeeded { user, error in
                            guard error == nil else {
                                print("Error refresh \(error)")
                                return
                            }
                            guard let user = user else { return }
                            guard let idToken = user.idToken else { return }
                            print("Got token: \(idToken.tokenString)")
                            self.network.getUser(token: idToken.tokenString)
                        }
                    }
                }
                ForEach((network.user?.studyBlocks ?? []).sorted(by: { a, b in
                    return a.endDate.compare(b.endDate) == ComparisonResult.orderedDescending
                })) { sb in
                    Section(header: Text(sb.name)) {
                        Text("\(sb.startDate) — \(sb.endDate)")
                        StudyBlockView(sb: sb)
                    }
                }
            }
        }.onAppear {
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                guard error == nil else {
                    print("Error restoring \(error.unsafelyUnwrapped)")
                    return
                }
                guard let user = user else { return }
                guard let idToken = user.idToken else { return }
                print("Got token: \(idToken.tokenString)")
                self.network.getUser(token: idToken.tokenString)
            }
        }.refreshable {
            self.network.getUser(token: GIDSignIn.sharedInstance.currentUser!.idToken!.tokenString)
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
