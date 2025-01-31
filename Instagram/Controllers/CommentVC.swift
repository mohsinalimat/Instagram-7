//
//  CommentVC.swift
//  Instagram
//
//  Created by Mohamed Ibrahem on 12/2/19.
//  Copyright © 2019 Mahmoud Saeed. All rights reserved.
//

import UIKit
import Firebase

class CommentVC: UIViewController {
    
    let cellId = "cellId"
    let testId = "testId"
    var post: Post?
    
    var commentView = CommentView()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = commentView
        tabBarController?.tabBar.isHidden = true
        
        let button = self.commentView.commentButton
        let collection = commentView.collectionView
        collection.keyboardDismissMode = .interactive
        collection.delegate = self
        collection.dataSource = self
        collection.register(CommentCell.self, forCellWithReuseIdentifier: cellId)
        
        button.addTarget(self, action: #selector(commentAction), for: .touchUpInside)
        
        loadComments()
    }
    var user: User?
    var comment = [Comment]()
    fileprivate func loadComments() {
        guard let postId = self.post?.id else {return}
        let dataRef = Database.database().reference().child("comments").child(postId)
        dataRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let val = snapshot.value as? [String: Any] else {return}
            val.forEach({ (key, value) in
                print(key)
                let commentRef = Database.database().reference().child("comments").child(postId).child(key)
                commentRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let values = snapshot.value as? [String: Any] else {return}
                    guard let uid = values["uid"] as? String else {return}
                    let userRef = Database.database().reference().child("users").child(uid)
                    userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        guard let userDict = snapshot.value as? [String: Any] else {return}
                        let user = User(dictionary: userDict)
                        let comment = Comment(user: user, dictionary: values)
                        self.comment.append(comment)
                        self.comment.sort(by: { (c1, c2) -> Bool in
                            return c1.commentDate.compare(c2.commentDate) == .orderedAscending
                        })
                        self.commentView.collectionView.reloadData()
                        self.scrolling()
                    }, withCancel: { (err) in
                        print("error fetch user:", err)
                    })
                }, withCancel: { (err) in
                    print("error fetch comment:", err)
                })
            })
        }) { (err) in
            print("error loading comments:", err)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        
    }
    
    
    @objc fileprivate func commentAction() {
        if self.commentView.commentTextfield.text != "" {
            guard let commentId = self.post?.id else {return}
            guard let uid = Auth.auth().currentUser?.uid else {return}
            
            let txtField = self.commentView.commentTextfield.text ?? ""
            let commentRef = Database.database().reference().child("comments").child(commentId).childByAutoId()
            let values = ["text": txtField,
                          "commentDate": Date().timeIntervalSince1970,
                          "uid": uid] as [String:Any]
            commentRef.updateChildValues(values) { (err, refernce) in
                if let err = err {
                    print("comment error:", err)
                    return
                }
                self.commentView.commentTextfield.text = ""
                print("seccessfully add comment.")
                self.comment.removeAll()
                self.commentView.collectionView.reloadData()
                self.loadComments()
                
            }
        } else {
            return
        }
    }
    
    fileprivate func scrolling() {
        let ind = self.comment.count - 1
        let index = IndexPath(item: ind, section: 0)
        self.commentView.collectionView.scrollToItem(at: index, at: .top, animated: true)
    }
    
    
    var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white
        containerView.frame = CGRect(x: 0, y: 0, width: 100, height: 70)
        return containerView
    }()
    
    override var inputAccessoryView: UIView? {
        get {
            containerView.addSubview(commentView.commentTextfield)
            containerView.addSubview(commentView.commentButton)
            containerView.addSubview(commentView.separetorView)
            addConstraints()
            return containerView
        }
    }
    
    fileprivate func addConstraints() {
        let txt = self.commentView.commentTextfield
        let button = self.commentView.commentButton
        let collection = self.commentView.collectionView
        let separetor = self.commentView.separetorView
        NSLayoutConstraint.activate([
            
            separetor.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            separetor.heightAnchor.constraint(equalToConstant: 0.5),
            separetor.topAnchor.constraint(equalTo: containerView.topAnchor),
            
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            button.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.2),
            
            txt.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            txt.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -10),
            txt.topAnchor.constraint(equalTo: containerView.topAnchor),
            txt.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            
            collection.widthAnchor.constraint(equalTo: commentView.widthAnchor),
            collection.topAnchor.constraint(equalTo: commentView.topAnchor),
            collection.bottomAnchor.constraint(equalTo: commentView.bottomAnchor, constant: -70),
            ])
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}
extension CommentVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.comment.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! CommentCell
        cell.comment = self.comment[indexPath.item]
        return cell
    }
}
extension CommentVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let messegeText = comment[indexPath.row].text as String? {
            let size = CGSize(width: view.frame.width, height: 100000000)
            let option = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            
            let esstimateFrame = NSString(string: messegeText).boundingRect(with: size, options: option, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)], context: nil)
            let height = max(40 + 40 + 8, esstimateFrame.height)
            return CGSize(width: view.frame.width - 18, height: height)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.5
    }
}


