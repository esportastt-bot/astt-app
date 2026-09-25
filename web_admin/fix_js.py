import re

with open('index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Strip the bad JS we added. We'll find it by looking for "let generatedAssignments"
if 'let generatedAssignments' in content:
    idx = content.find('let generatedAssignments')
    # strip until the end of the script tag
    end_idx = content.find('</script>\n</body>', idx)
    content = content[:idx] + content[end_idx:]

js_html = """
    let generatedAssignments = [];

    function readXlsx(file) {
        return new Promise((resolve) => {
            const reader = new FileReader();
            reader.onload = (e) => {
                const data = e.target.result;
                const workbook = XLSX.read(data, {type: 'binary'});
                const firstSheetName = workbook.SheetNames[0];
                const worksheet = workbook.Sheets[firstSheetName];
                const json = XLSX.utils.sheet_to_json(worksheet, {header: 1, raw: false});
                resolve(json);
            };
            reader.readAsBinaryString(file);
        });
    }

    async function generateDistribution() {
        const helloFile = document.getElementById('helloAssoFile').files[0];
        const codesFile = document.getElementById('codesFile').files[0];
        if(!helloFile || !codesFile) return alert("Veuillez sélectionner les 2 fichiers Excel d'abord.");

        try {
            const helloData = await readXlsx(helloFile);
            const codesData = await readXlsx(codesFile);

            let usersNeeded = {};
            // Start from 1 to skip header
            for(let i=1; i<helloData.length; i++) {
                let row = helloData[i];
                if(!row || row.length === 0) continue;
                let email = row[8]; // I
                let tarif = row[12]; // M
                if(email && tarif) {
                    let amountStr = tarif.toString().replace(',', '.').replace('€', '').trim();
                    let amount = parseFloat(amountStr);
                    if(!isNaN(amount) && amount > 0) {
                        let nbCodes = Math.floor(amount / 10);
                        if(nbCodes > 0) {
                            usersNeeded[email] = (usersNeeded[email] || 0) + nbCodes;
                        }
                    }
                }
            }

            let availableCodes = [];
            for(let i=1; i<codesData.length; i++) {
                let row = codesData[i];
                if(!row || row.length === 0) continue;
                let code = row[1]; // B
                let dateLimite = row[6] || ''; // G
                if(code) {
                    availableCodes.push({ code: code.toString().trim(), date: dateLimite.toString().trim() });
                }
            }

            generatedAssignments = [];
            let codeIndex = 0;
            for(let email in usersNeeded) {
                let needed = usersNeeded[email];
                for(let k=0; k<needed; k++) {
                    if(codeIndex < availableCodes.length) {
                        generatedAssignments.push({
                            id: Math.random().toString(36).substr(2, 9),
                            email: email.trim().toLowerCase(),
                            code: availableCodes[codeIndex].code,
                            dateLimite: availableCodes[codeIndex].date
                        });
                        codeIndex++;
                    }
                }
            }

            if (generatedAssignments.length === 0) {
                alert("Aucun code n'a pu être attribué. Vérifiez le format des fichiers (les colonnes doivent correspondre).");
            }

            renderDistributionTable();
            document.getElementById('distributionPreview').classList.remove('hidden');

        } catch (err) {
            console.error(err);
            alert("Erreur lors de la lecture des fichiers : " + err.message);
        }
    }

    function renderDistributionTable() {
        const tbody = document.getElementById('distributionTableBody');
        tbody.innerHTML = '';
        generatedAssignments.forEach((item, index) => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><input type="text" class="form-control bg-dark text-white border-secondary" value="${item.email}" onchange="updateAssignment('${item.id}', 'email', this.value)"></td>
                <td><input type="text" class="form-control bg-dark text-info border-secondary" value="${item.code}" onchange="updateAssignment('${item.id}', 'code', this.value)"></td>
                <td><input type="text" class="form-control bg-dark text-white border-secondary" value="${item.dateLimite}" onchange="updateAssignment('${item.id}', 'dateLimite', this.value)"></td>
                <td><button class="btn btn-sm btn-danger" onclick="removeAssignment('${item.id}')"><i class="fas fa-trash"></i></button></td>
            `;
            tbody.appendChild(tr);
        });
    }

    function updateAssignment(id, field, value) {
        const item = generatedAssignments.find(x => x.id === id);
        if(item) {
            item[field] = value;
        }
    }

    function removeAssignment(id) {
        generatedAssignments = generatedAssignments.filter(x => x.id !== id);
        renderDistributionTable();
    }

    async function saveDistributionToFirebase() {
        if(generatedAssignments.length === 0) return alert("Rien à envoyer.");
        if(!confirm("Êtes-vous sûr de vouloir envoyer ces " + generatedAssignments.length + " codes vers la base de données ? Les utilisateurs concernés les verront apparaître dans leur application.")) return;
        
        try {
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
            }
            
            showToast(successCount + " code(s) distribué(s) avec succès !");
            document.getElementById('distributionPreview').classList.add('hidden');
            generatedAssignments = [];
            
        } catch (err) {
            console.error(err);
            alert("Erreur Firebase : " + err.message);
        }
    }
"""

content = content.replace('</script>\n</body>', js_html + '\n</script>\n</body>')

with open('index.html', 'w', encoding='utf-8') as f:
    f.write(content)

