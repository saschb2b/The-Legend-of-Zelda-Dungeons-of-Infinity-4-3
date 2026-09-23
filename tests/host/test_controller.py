import unittest

from controller import normalize_mapping


class ControllerTests(unittest.TestCase):
    def test_nintendo_mapping_restores_snes_button_positions(self):
        source = '\n# nintendo layout\nguid,Nova,a:b1,b:b0,x:b2,y:b3,start:b7,platform:Linux,\n'
        expected = '\n# nintendo layout\nguid,Nova,b:b1,a:b0,x:b2,y:b3,start:b7,platform:Linux,\n'
        self.assertEqual(normalize_mapping(source), expected)

    def test_each_connected_controller_keeps_its_button_indices(self):
        source = '# Nintendo Layout\ng1,One,a:b3,b:b2,\ng2,Two,a:b8,b:b9,\n'
        expected = '# Nintendo Layout\ng1,One,b:b3,a:b2,\ng2,Two,b:b8,a:b9,\n'
        self.assertEqual(normalize_mapping(source), expected)

    def test_xbox_custom_and_empty_mappings_are_preserved(self):
        for header in ('# xbox layout\n', '# custom layout\n', ''):
            source = header + 'guid,Controller,a:b0,b:b1,x:b2,y:b3,'
            self.assertEqual(normalize_mapping(source), source)
        self.assertEqual(normalize_mapping(''), '')

    def test_controller_names_and_other_controls_are_preserved(self):
        source = '# nintendo layout\nguid,a: special controller,back:b8,leftx:a0,b:b4,a:b5,\n'
        self.assertEqual(normalize_mapping(source), '# nintendo layout\nguid,a: special controller,back:b8,leftx:a0,a:b4,b:b5,\n')
