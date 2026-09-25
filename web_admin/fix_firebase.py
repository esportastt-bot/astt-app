import re

with open('index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the Firebase saving logic in index.html
old_js = """        try {
            const usersRef = db.collection('users');
            let successCount = 0;
            
            for(let item of generatedAssignments) {
                if(!item.email || !item.code) continue;
                
                let targetUid = null;
                let q = await usersRef.where('email', '==', item.email).get();
                if(!q.empty) {
                    targetUid = q.docs[0].id;
                } else {
                    let newDoc = usersRef.doc();
                    await newDoc.set({
                        email: item.email,
                        isStaff: false,
                        createdAt: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    targetUid = newDoc.id;
                }
                
                await usersRef.doc(targetUid).collection('codes').add({
                    code: item.code,
                    game: "Jeu (Date limite: " + item.dateLimite + ")",
                    isUsed: false,
                    createdAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                successCount++;
            }"""

new_js = """        try {
            const codesRef = db.collection('distributed_codes');
            let successCount = 0;
            
            for(let item of generatedAssignments) {
                if(!item.email || !item.code) continue;
                
                await codesRef.add({
                    email: item.email.toLowerCase(),
                    code: item.code,
                    game: "Jeu (Date limite: " + item.dateLimite + ")",
                    isUsed: false,
                    createdAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                successCount++;
            }"""

content = content.replace(old_js, new_js)

with open('index.html', 'w', encoding='utf-8') as f:
    f.write(content)

