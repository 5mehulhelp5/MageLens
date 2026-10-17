window.probeRequest = async function (url, formKey, value) {
    const cookie = document.cookie.split('; ').find(value => value.startsWith('form_key='));
    const currentKey = window.hyva?.getFormKey?.() || (cookie ? decodeURIComponent(cookie.slice('form_key='.length)) : formKey);
    const response = await fetch(url, {method: 'POST', body: new URLSearchParams({form_key: currentKey, value})});
    if (!response.ok) throw new Error('Probe save failed');
    return response.json();
};
window.coverageProbe = function (url, formKey) {
    return {name: 'initial', count: 0, saved: '', open: false, items: ['one', 'two'],
        increment() { this.count++; },
        async save() { this.saved = (await window.probeRequest(url, formKey, this.name)).message; },
        unused() { throw new Error('Unvisited method'); }
    };
};
