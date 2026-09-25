
    const firebaseConfig = {
        apiKey: "AIzaSyDFE6P0GHVGcC5VBjwg32eyZrhLp1JmKBg",
        authDomain: "astt-e-sport.firebaseapp.com",
        projectId: "astt-e-sport",
        storageBucket: "astt-e-sport.firebasestorage.app",
        messagingSenderId: "678391264155",
        appId: "1:678391264155:web:b0b4faa4233837034de73e"
    };

    firebase.initializeApp(firebaseConfig);
    const auth = firebase.auth();
    const db = firebase.firestore();

    let editingAnnounceId = null;
    let announcementsData = {};

    function showToast(msg = "SauvegardÃ© !", isError = false) {
        const toastEl = document.getElementById('saveToast');
        toastEl.classList.remove('text-bg-success', 'text-bg-danger');
        toastEl.classList.add(isError ? 'text-bg-danger' : 'text-bg-success');
        document.getElementById('toastMsg').textContent = msg;
        new bootstrap.Toast(toastEl, { delay: 3000 }).show();
    }

    function formatDateForInput(firebaseTimestamp) {
        if (!firebaseTimestamp) return "";
        const date = firebaseTimestamp.toDate();
        // Format YYYY-MM-DDTHH:mm
        date.setMinutes(date.getMinutes() - date.getTimezoneOffset());
        return date.toISOString().slice(0, 16);
    }
    
    function parseDateFromInput(value) {
        if (!value) return null;
        return firebase.firestore.Timestamp.fromDate(new Date(value));
    }

    function toggleLiveDates() {
        const state = parseInt(document.getElementById('liveState').value);
        if (state === 1) document.getElementById('liveScheduledDateContainer').classList.remove('hidden');
        else document.getElementById('liveScheduledDateContainer').classList.add('hidden');
    }

    function toggleTournoiDates() {
        const state = parseInt(document.getElementById('tournoiState').value);
        if (state === 1) {
            document.getElementById('tournoiRegDateContainer').classList.remove('hidden');
            document.getElementById('tournoiStartDateContainer').classList.remove('hidden');
        } else if (state === 2) {
            document.getElementById('tournoiRegDateContainer').classList.add('hidden');
            document.getElementById('tournoiStartDateContainer').classList.remove('hidden');
        } else {
            document.getElementById('tournoiRegDateContainer').classList.add('hidden');
            document.getElementById('tournoiStartDateContainer').classList.add('hidden');
        }
    }

    auth.onAuthStateChanged(user => {
        if (user) {
            document.getElementById('loginSection').classList.add('hidden');
            document.getElementById('dashboardSection').classList.remove('hidden');
            document.getElementById('btnLogout').classList.remove('hidden');
            loadStatus();
            loadAnnouncements();
            loadArchives();
        } else {
            document.getElementById('loginSection').classList.remove('hidden');
            document.getElementById('dashboardSection').classList.add('hidden');
            document.getElementById('btnLogout').classList.add('hidden');
        }
    });

    document.getElementById('loginForm').addEventListener('submit', e => {
        e.preventDefault();
        auth.signInWithEmailAndPassword(
            document.getElementById('emailInput').value,
            document.getElementById('passwordInput').value
        ).catch(() => {
            document.getElementById('loginError').innerText = "Erreur de connexion. VÃ©rifiez vos identifiants.";
            document.getElementById('loginError').classList.remove('hidden');
        });
    });

    document.getElementById('btnLogout').addEventListener('click', () => auth.signOut());

    function loadStatus() {
        db.collection('app_state').doc('status').onSnapshot(doc => {
            if (!doc.exists) return;
            const data = doc.data();

            let liveState = data.liveState;
            if (liveState === undefined) liveState = data.isLiveActive ? 2 : 0;
            document.getElementById('liveState').value = liveState;
            document.getElementById('liveScheduledDate').value = formatDateForInput(data.liveScheduledDate);
            toggleLiveDates();
            
            document.getElementById('liveTitle').value = data.liveTitle || "";
            document.getElementById('liveDesc').value = data.liveDesc || "";

            let tournoiState = data.tournamentState;
            if (tournoiState === undefined) tournoiState = data.isTournamentActive ? 1 : 0;
            document.getElementById('tournoiState').value = tournoiState;
            document.getElementById('tournoiRegEndDate').value = formatDateForInput(data.tournamentRegistrationEndDate);
            document.getElementById('tournoiStartDate').value = formatDateForInput(data.tournamentStartDate);
            toggleTournoiDates();

            document.getElementById('tournoiTitle').value = data.tournamentTitle || "";
            document.getElementById('tournoiDesc').value = data.tournamentDesc || "";
            document.getElementById('tournoiUrl').value = data.tournamentUrl || "";

            document.getElementById('twitchUrl').value = data.twitchUrl || "";
            document.getElementById('discordUrl').value = data.discordUrl || "";
            document.getElementById('youtubeUrl').value = data.youtubeUrl || "";

            document.getElementById('testModeActive').checked = data.isTestMode || false;
            
            const currentFirebaseVersion = data.latestAppVersionName || data.latestAppVersionCode || "1";
            document.getElementById('currentFirebaseVersion').innerText = currentFirebaseVersion;
            document.getElementById('updateVersion').value = currentFirebaseVersion;
            document.getElementById('updateUrl').value = data.updateUrl || "";
            document.getElementById('updateMessage').value = data.updateMessage || "";
        });
    }

    document.getElementById('testModeActive').addEventListener('change', async function () {
        const isActive = this.checked;
        try {
            await db.collection('app_state').doc('status').set({ isTestMode: isActive }, { merge: true });
            showToast(isActive ? "Mode Test ACTIVÃ‰ ðŸš§" : "Mode Test DÃ‰SACTIVÃ‰ âœ…");
        } catch (e) {
            showToast("Erreur : " + e.message, true);
            this.checked = !isActive;
        }
    });

    window.saveLiveContent = async function () {
        const state = parseInt(document.getElementById('liveState').value);
        let updates = {
            liveState: state,
            liveTitle: document.getElementById('liveTitle').value,
            liveDesc: document.getElementById('liveDesc').value,
        };
        
        if (state === 1) {
            updates.liveScheduledDate = parseDateFromInput(document.getElementById('liveScheduledDate').value);
        } else {
            updates.liveScheduledDate = firebase.firestore.FieldValue.delete();
        }

        try {
            await db.collection('app_state').doc('status').set(updates, { merge: true });
            showToast("Configuration Live sauvegardÃ©e âœ…");
        } catch (e) { showToast("Erreur : " + e.message, true); }
    };

    window.saveTournoiContent = async function () {
        const state = parseInt(document.getElementById('tournoiState').value);
        let updates = {
            tournamentState: state,
            tournamentTitle: document.getElementById('tournoiTitle').value,
            tournamentDesc: document.getElementById('tournoiDesc').value,
            tournamentUrl: document.getElementById('tournoiUrl').value,
        };

        if (state === 1 || state === 2) {
            updates.tournamentStartDate = parseDateFromInput(document.getElementById('tournoiStartDate').value);
        } else {
            updates.tournamentStartDate = firebase.firestore.FieldValue.delete();
        }

        if (state === 1) {
            updates.tournamentRegistrationEndDate = parseDateFromInput(document.getElementById('tournoiRegEndDate').value);
        } else {
            updates.tournamentRegistrationEndDate = firebase.firestore.FieldValue.delete();
        }

        try {
            await db.collection('app_state').doc('status').set(updates, { merge: true });
            showToast("Configuration Tournoi sauvegardÃ©e âœ…");
        } catch (e) { showToast("Erreur : " + e.message, true); }
    };

    window.saveSocialContent = async function () {
        try {
            await db.collection('app_state').doc('status').set({
                twitchUrl: document.getElementById('twitchUrl').value,
                discordUrl: document.getElementById('discordUrl').value,
                youtubeUrl: document.getElementById('youtubeUrl').value,
            }, { merge: true });
            showToast("RÃ©seaux sociaux mis Ã  jour âœ…");
        } catch (e) { showToast("Erreur : " + e.message, true); }
    };

    window.saveUpdateContent = async function () {
        try {
            await db.collection('app_state').doc('status').set({
                latestAppVersionName: document.getElementById('updateVersion').value,
                updateUrl: document.getElementById('updateUrl').value,
                updateMessage: document.getElementById('updateMessage').value,
            }, { merge: true });
            showToast("Alerte de mise Ã  jour dÃ©ployÃ©e âœ…");
        } catch (e) { showToast("Erreur : " + e.message, true); }
    };

    function loadArchives() {
        db.collection('tournaments').orderBy('updatedAt', 'desc').onSnapshot(snap => {
            const list = document.getElementById('archivesList');
            if(!list) return;
            if (snap.empty) {
                list.innerHTML = "<div class='text-center text-muted mt-3 fs-5'>Aucun tournoi archivÃ©.</div>";
                return;
            }
            list.innerHTML = "";
            snap.forEach(doc => {
                const a = doc.data();
                const replayUrl = a.replayUrl || "";
                list.innerHTML += `
                    <div class="list-group-item bg-dark text-white border-secondary d-flex justify-content-between align-items-center mb-2 rounded">
                        <div>
                            <h5 class="mb-1 text-warning">${a.title || 'Sans titre'}</h5>
                            <small class="text-muted">ID: ${doc.id}</small>
                        </div>
                        <div class="d-flex gap-2">
                            <button class="btn ${replayUrl ? 'btn-outline-info' : 'btn-outline-secondary'}" onclick="editReplay('${doc.id}', '${replayUrl.replace(/'/g, "\'")}')" title="Modifier le lien Replay YouTube">
                                <i class="fab fa-youtube text-danger"></i> Replay
                            </button>
                            <button class="btn btn-outline-danger" onclick="deleteArchive('${doc.id}')" title="Supprimer">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    </div>
                `;
            });
        });
    }

    window.editReplay = function(id, currentUrl) {
        const newUrl = prompt("Entrez le lien YouTube du replay pour ce tournoi :", currentUrl);
        if(newUrl !== null) {
            db.collection('tournaments').doc(id).update({ replayUrl: newUrl.trim() })
                .then(() => showToast("Lien Replay mis Ã  jour ! âœ…"))
                .catch(e => showToast("Erreur : " + e.message, true));
        }
    };

    window.deleteArchive = function(id) {
        if (confirm("Voulez-vous vraiment supprimer dÃ©finitivement les donnÃ©es de ce tournoi ?")) {
            db.collection('tournaments').doc(id).delete()
                .then(() => showToast("Tournoi supprimÃ© âœ…"))
                .catch(e => showToast("Erreur : " + e.message, true));
        }
    };

    function loadAnnouncements() {
        db.collection('announcements').orderBy('createdAt', 'desc').onSnapshot(snap => {
            const list = document.getElementById('announcementsList');
            announcementsData = {};
            if (snap.empty) {
                list.innerHTML = "<div class='text-center text-muted mt-5 fs-5'>Aucune annonce.</div>";
                return;
            }
            list.innerHTML = "";
            snap.forEach(doc => {
                const a = doc.data();
                announcementsData[doc.id] = a;
                const dateText = a.createdAt ? new Date(a.createdAt.toDate()).toLocaleDateString('fr-FR') : 'Ã€ l\'instant';
                list.innerHTML += `
                    <div class="announcement-row d-flex justify-content-between align-items-start">
                        <div class="pe-4 w-100">
                            <h4 class="text-info mb-1">${a.title}</h4>
                            <p class="small text-muted mb-2">PubliÃ©e le ${dateText}</p>
                            <p class="text-light fs-5" style="white-space: pre-wrap;">${a.description}</p>
                            ${a.linkUrl || a.actionUrl ? `<a href="${a.linkUrl || a.actionUrl}" target="_blank" class="btn btn-sm btn-outline-warning mt-2"><i class="fas fa-external-link-alt"></i> Tester le bouton</a>` : ''}
                        </div>
                        <div class="d-flex flex-column gap-2 ms-2">
                            <button class="btn btn-primary btn-lg" onclick="editAnnouncement('${doc.id}')" title="Modifier"><i class="fas fa-edit"></i></button>
                            <button class="btn btn-danger btn-lg" onclick="deleteAnnouncement('${doc.id}')" title="Supprimer"><i class="fas fa-trash"></i></button>
                        </div>
                    </div>
                `;
            });
        });
    }

    window.editAnnouncement = function (id) {
        editingAnnounceId = id;
        const a = announcementsData[id];
        document.getElementById('newAnnounceTitle').value = a.title;
        document.getElementById('newAnnounceDesc').value = a.description;
        document.getElementById('newAnnounceLinkText').value = a.linkText || "";
        document.getElementById('newAnnounceUrl').value = a.actionUrl || a.linkUrl || "";
        document.getElementById('formTitle').innerHTML = '<i class="fas fa-pen"></i> Modifier l\'annonce';
        document.getElementById('formTitle').classList.replace('bg-primary', 'bg-success');
        const btn = document.getElementById('btnSubmitAnnounce');
        btn.innerHTML = '<i class="fas fa-save"></i> Enregistrer les modifications';
        btn.classList.replace('btn-primary', 'btn-success');
        document.getElementById('btnCancelEdit').classList.remove('hidden');
        window.scrollTo(0, 0);
    };

    window.cancelEdit = function () {
        editingAnnounceId = null;
        document.getElementById('newAnnounceTitle').value = "";
        document.getElementById('newAnnounceDesc').value = "";
        document.getElementById('newAnnounceLinkText').value = "";
        document.getElementById('newAnnounceUrl').value = "";
        document.getElementById('formTitle').innerHTML = '<i class="fas fa-plus-circle"></i> CrÃ©er une annonce';
        document.getElementById('formTitle').classList.replace('bg-success', 'bg-primary');
        const btn = document.getElementById('btnSubmitAnnounce');
        btn.innerHTML = '<i class="fas fa-paper-plane"></i> Publier l\'annonce';
        btn.classList.replace('btn-success', 'btn-primary');
        document.getElementById('btnCancelEdit').classList.add('hidden');
    };

    window.submitAnnouncement = async function () {
        const title = document.getElementById('newAnnounceTitle').value;
        const desc = document.getElementById('newAnnounceDesc').value;
        const linkText = document.getElementById('newAnnounceLinkText').value;
        const url = document.getElementById('newAnnounceUrl').value;
        if (!title || !desc) { showToast("Titre et description obligatoires.", true); return; }

        try {
            if (editingAnnounceId) {
                await db.collection('announcements').doc(editingAnnounceId).update({ title, description: desc, linkText: linkText, actionUrl: url });
                showToast("Annonce modifiÃ©e âœ…");
            } else {
                await db.collection('announcements').add({
                    title, description: desc, linkText: linkText, actionUrl: url,
                    createdAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                showToast("Annonce publiÃ©e â€” notification envoyÃ©e ! ðŸ“¢");
            }
            cancelEdit();
        } catch (e) { showToast("Erreur : " + e.message, true); }
    };

    window.deleteAnnouncement = function (id) {
        if (confirm("Attention, cette suppression est dÃ©finitive. Confirmer ?")) {
            db.collection('announcements').doc(id).delete();
            if (editingAnnounceId === id) cancelEdit();
        }
    };

    
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

