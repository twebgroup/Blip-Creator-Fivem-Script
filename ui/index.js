let selSprd = null;
let selCold = null;

let sendData = (field, value) => {
    $.post('http://blip-editor/return', JSON.stringify({type: field, data: value}));
}

let receiveData = (field, value) => {
    switch (field) {
        case 'sprite':
            $("#blip_" + value).click();
            break;
        case 'color':
            $("#col_" + value).click();
            break;
        case 'scale':
            scalerange.value = value;
            scalerange.onchange();
            break;
        case 'alpha':
            alpharange.value = value;
            alpharange.onchange();
            break;
        case 'name':
            inp_name.onchange();
            break;
        case 'bCheckmark':
            bCheckmark.checked = value;
            break;
        case 'bHeightIndicator':
            bHeightIndicator.checked = value;
            break;
        case 'bHeadingIndicator':
            bHeadingIndicator.checked = value;
            break;
        case 'bShrink':
            bShrink.checked = value;
            break;
        case 'bOutline':
            bOutline.checked = value;
            break;
        default:
            $("#" + field).value = value;
            break;
    }
}

window.addEventListener('message', (ev) => {
    let method = ev.data.method;
    let data = ev.data.data;

    switch (method) {
        case 'open':
            beDisp();
            break;
        case 'close':
            beHide();
            break;
        case 'updateBlips':
            updateBlipsList(data);
            break;
        case 'updateInputValue':
            document.getElementById(data.inputId).value = data.value;
            break;
        case 'resetForm':
            // Form elemanlarını sıfırla
            document.getElementById('inp_name').value = "";
            document.getElementById('scalerange').value = 7;
            document.getElementById('scalerangepreview').innerHTML = "0.70";
            document.getElementById('alpharange').value = 255;
            document.getElementById('alpharangepreview').innerHTML = "100";
            
            // Checkbox'ları sıfırla
            document.getElementById('bCheckmark').checked = false;
            document.getElementById('bHeightIndicator').checked = false;
            document.getElementById('bHeadingIndicator').checked = false;
            document.getElementById('bShrink').checked = false;
            document.getElementById('bOutline').checked = false;
            
            // Sprite ve renk seçimlerini sıfırla
            if (selSprd) selSprd.setAttribute('class', 'sprite');
            if (selCold) selCold.setAttribute('class', 'color');
            selSprd = null;
            selCold = null;
            
            // Preview'ları temizle
            document.getElementById('spritepreview').innerHTML = "";
            document.getElementById('colorpreview').innerHTML = "";
            
            // Save butonunu sıfırla
            document.getElementById('btn_save').innerHTML = '<i class="fas fa-save"></i> Save';
            break;
        default:
            receiveData(method, data);
            break;
    }
})

beDisp = () => {main.style['display'] = 'block'};
beHide = () => {main.style['display'] = 'none'};

window.onload = () => {
    let sprd = document.getElementById('sprites');
    let cold = document.getElementById('colors');
    let sprp = document.getElementById('spritepreview');
    let colp = document.getElementById('colorpreview');
    let sprites = spriteList();
    let colors = colorList();
    for (let sprite of sprites) {
        let elem = document.createElement('img');
        elem.src = sprite[1];
        elem.setAttribute('class', 'sprite');
        elem.setAttribute('id', 'blip_' + sprite[0]);
        elem.onclick = () => {
            sprp.innerHTML = "";
            if (selSprd != null) {
                selSprd.setAttribute('class', 'sprite');
            }
            elem.setAttribute('class', 'sprite sprite-selected');
            selSprd = elem;
            let spriteId = parseInt(sprite[0]);
            sendData("sprite", spriteId);
            let clone = selSprd.cloneNode(true);
            clone.style['vertical-align'] = 'text-bottom';
            sprp.classList.add('selected');
            sprp.appendChild(clone);
        }
        sprd.appendChild(elem);
    }
    for (let color of colors) {
        let elem = document.createElement('div');
        elem.style['background-color'] = '#' + color[2];
        elem.setAttribute('class', 'color');
        elem.setAttribute('id', 'col_' + color[0]);
        elem.onclick = () => {
            colp.innerHTML = "";
            if (selCold != null) {
                selCold.setAttribute('class', 'color');
            }
            elem.setAttribute('class', 'color color-selected');
            selCold = elem;
            sendData("color", color[0]);
            let preview = document.createElement('div');
            preview.setAttribute('class', 'badge');
            preview.style.backgroundColor = '#' + color[2];
            colp.classList.add('selected');
            colp.appendChild(preview);
        }
        cold.appendChild(elem);
    }

    scalerange.value = 7;
    scalerangepreview.innerHTML = '0.70';
    scalerange.oninput = () => {
        let val = (scalerange.value / 10).toFixed(2);
        scalerangepreview.innerHTML = val;
        sendData("scale", scalerange.value);
    }
    scalerange.onchange = scalerange.oninput;

    alpharange.oninput = () => {
        let val = alpharange.value;
        let percent = Math.round((val / 255) * 100);
        alpharangepreview.innerHTML = percent;
        sendData("alpha", val);
    }
    alpharange.onchange = alpharange.oninput;

    bCheckmark.onchange = () => {
        sendData("bCheckmark", bCheckmark.checked);
    }
    bHeightIndicator.onchange = () => {
        sendData("bHeightIndicator", bHeightIndicator.checked);
    }
    bHeadingIndicator.onchange = () => {
        sendData("bHeadingIndicator", bHeadingIndicator.checked);
    }
    bShrink.onchange = () => {
        sendData("bShrink", bShrink.checked);
    }
    bOutline.onchange = () => {
        sendData("bOutline", bOutline.checked);
    }

    inp_name.oninput = () => {
        let val = inp_name.value;
        if (val.trim() === '') val = 'Editor Blip';
        sendData("name", val);
    }
    inp_name.onchange = inp_name.oninput;

    btn_discard.onclick = () => {
        sendData("finish", "discard");
        beHide();
    }
    btn_save.onclick = () => {
        sendData("finish", "save");
        beHide();
    }
    btn_delete.onclick = () => {
        sendData("finish", "delete");
        const blipsList = document.getElementById('blipsList');
        blipsList.innerHTML = '';
        beHide();
    }
}

function CloseMenu() {
    const container = document.querySelector('.container');
    container.classList.add('closing');
    
    setTimeout(() => {
        sendData("finish", "discard");
        beHide();
    }, 150);
}

document.addEventListener('keyup', function(e) {
    if (e.key === "Escape") {
        CloseMenu();
    }
});

document.addEventListener('click', function(e) {
    if (e.target.id === 'main') {
        CloseMenu();
    }
});

function updateBlipsList(blips) {
    const blipsList = document.getElementById('blipsList');
    const searchInput = document.getElementById('searchBlips');
    blipsList.innerHTML = '';

    const filteredBlips = blips.filter(blip => 
        blip && 
        blip.name && 
        blip.name !== 'Düzenlenecek' && 
        blip.name.trim() !== ''
    );

    filteredBlips.forEach(blip => {
        const blipItem = document.createElement('div');
        blipItem.className = 'blip-item';
        blipItem.dataset.blipId = blip.id;
        blipItem.innerHTML = `
            <div class="blip-info">
                <img src="${getBlipSprite(blip.sprite)}" alt="Blip Icon">
                <span>${blip.name}</span>
            </div>
            <div class="blip-actions">
                <button class="delete-action" data-blip-id="${blip.id}">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        `;
        
        const deleteBtn = blipItem.querySelector('.delete-action');
        deleteBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            
            blipItem.classList.add('deleting');
            
            const blipId = deleteBtn.getAttribute('data-blip-id');
            
            setTimeout(() => {
                deleteBlip(blipId);
                blipItem.remove();
            }, 300);
        });
        
        blipsList.appendChild(blipItem);
    });

    if (searchInput) {
        searchInput.oninput = () => {
            const searchTerm = searchInput.value.toLowerCase();
            const blipItems = blipsList.getElementsByClassName('blip-item');
            
            Array.from(blipItems).forEach(item => {
                const name = item.querySelector('span').textContent.toLowerCase();
                item.style.display = name.includes(searchTerm) ? 'flex' : 'none';
            });
        };
    }
}

function getBlipSprite(spriteId) {
    const sprites = spriteList();
    for (let sprite of sprites) {
        if (sprite[0] == spriteId) {
            return sprite[1];
        }
    }
    return '';
}

document.getElementById('btn_save').addEventListener('click', function() {
    const isUpdate = this.innerHTML.includes('Güncelle');
    if (isUpdate) {
        sendData("finish", "update");
    } else {
        sendData("finish", "save");
    }
    beHide();
});

document.getElementById('btn_delete').addEventListener('click', function() {
    sendData("finish", "delete");
    
    const selectedBlip = document.querySelector('.blip-item.selected');
    if (selectedBlip) {
        selectedBlip.remove();
    }
    
    resetForm();
    beHide();
});

function resetForm() {
    const saveBtn = document.getElementById('btn_save');
    saveBtn.innerHTML = '<i class="fas fa-save"></i> Save';
    document.getElementById('inp_name').value = '';
    document.getElementById('scalerange').value = 7;
    document.getElementById('scalerangepreview').innerHTML = '0.70';
}

function deleteBlip(blipId) {
    if (blipId) {
        sendData("deleteBlip", {
            id: blipId,
            removeFromList: true
        });
    }
}
